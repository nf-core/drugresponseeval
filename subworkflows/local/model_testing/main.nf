include { PREDICT_FULL                                  } from '../../../modules/local/predict_full'
include { RANDOMIZATION_SPLIT                           } from '../../../modules/local/randomization_split'
include { RANDOMIZATION_TEST                            } from '../../../modules/local/randomization_test'
include { ROBUSTNESS_TEST                               } from '../../../modules/local/robustness_test'
include { FINAL_SPLIT                                   } from '../../../modules/local/final_split'
include { TUNE_FINAL_MODEL                              } from '../../../modules/local/tune_final_model'
include { EVALUATE_FIND_MAX as EVALUATE_FIND_MAX_FINAL  } from '../../../modules/local/evaluate_find_max'
include { TRAIN_FINAL_MODEL                             } from '../../../modules/local/train_final_model'
include { CONSOLIDATE_RESULTS                           } from '../../../modules/local/consolidate_results'
include { EVALUATE_FINAL                                } from '../../../modules/local/evaluate_final'
include { COLLECT_RESULTS                               } from '../../../modules/local/collect_results'
include { VISUALIZE_RESULTS                             } from '../../../modules/local/visualize_results'


workflow MODEL_TESTING {
    take:
    ch_models_baselines         // from input [model_class, model_name]
    best_hpam_per_split         // from RUN_CV: [split_id, test_mode, split_dataset, model_name, best_hpam_combi_X.yaml]
    randomizations              // from input
    response_dataset            // from LOAD_RESPONSE
    cross_study_datasets        // from LOAD_RESPONSE
    ch_models                  // from RUN_CV [model_class, model_name]
    work_path                  // from input
    test_modes                 // e.g., ['LPO', 'LCO']
    ch_hpam_combis              // from RUN_CV [model_name, hpam_X.yaml]

    main:
    ch_versions = Channel.empty()
    if (params.cross_study_datasets == '') {
        cross_study_datasets = channel.fromPath(['./NONE.csv'])
    }
    ch_tmp = best_hpam_per_split.map{
        split_id, test_mode, path_to_split, model_name, path_to_hpams ->
        return [model_name, test_mode, split_id, path_to_split, path_to_hpams]
    }
    ch_tmp2 = cross_study_datasets
                            .collect()
                            .map{it -> [it]}
    // [[cross_study_datasets], model, test_mode, split_id, split_dataset, best_hpam_combi_X.yaml, path/to/data]
    ch_predict_final = ch_tmp2.combine(ch_tmp).combine(work_path)

    PREDICT_FULL (
        ch_predict_final,
        params.response_transformation,
        params.model_checkpoint_dir
    )
    ch_versions = ch_versions.mix(PREDICT_FULL.out.versions)
    ch_vis = PREDICT_FULL.out.ch_vis.concat(PREDICT_FULL.out.ch_cross)

    if (params.randomization_mode != 'None') {
        ch_randomization = channel.from(randomizations)
        // randomizations only for models, not for baselines
        ch_models_rand = ch_models
                            .map{it -> it[0]}
                            .unique()
                            .combine(ch_randomization)
        RANDOMIZATION_SPLIT (
            ch_models_rand
        )
        ch_versions = ch_versions.mix(RANDOMIZATION_SPLIT.out.versions)
        ch_rand_views = ch_models
                        .combine(RANDOMIZATION_SPLIT.out.randomization_test_views.transpose(), by: 0)
                        .map{ model_class, model_name, rand_file -> [model_name, rand_file] }

        ch_best_hpams_per_split_rand = best_hpam_per_split.map {
            split_id, test_mode, path_to_split, model_name, path_to_hpams ->
            return [model_name, test_mode, split_id, path_to_split, path_to_hpams]
        }
        // [model_name, test_mode, split_id, split_dataset, best_hpam_combi_X.yaml,
        // randomization_views]
        ch_randomization = ch_best_hpams_per_split_rand
                            .combine(ch_rand_views, by: 0)
                            .combine(work_path)

        RANDOMIZATION_TEST (
            ch_randomization,
            params.randomization_type,
            params.response_transformation,
            params.model_checkpoint_dir
        )
        ch_versions = ch_versions.mix(RANDOMIZATION_TEST.out.versions)
        ch_vis = ch_vis.concat(RANDOMIZATION_TEST.out.ch_vis)
    }

    if (params.n_trials_robustness > 0) {
        ch_trials_robustness = Channel.from(1..params.n_trials_robustness)
        ch_trials_robustness = ch_models
                                .map{it -> it[1]}
                                .combine(ch_trials_robustness)

        ch_best_hpams_per_split_rob = best_hpam_per_split.map {
            split_id, test_mode, path_to_split, model_name, path_to_hpams ->
            return [model_name, test_mode, split_id, path_to_split, path_to_hpams]
        }

        // [model_name, test_mode, split_id, split_dataset, best_hpam_combi_X.yaml,
        // robustness_iteration]
        ch_robustness = ch_best_hpams_per_split_rob.combine(ch_trials_robustness, by: 0).combine(work_path)
        ROBUSTNESS_TEST (
            ch_robustness,
            params.randomization_type,
            params.response_transformation,
            params.model_checkpoint_dir
        )
        ch_versions = ch_versions.mix(ROBUSTNESS_TEST.out.versions)
        ch_vis = ch_vis.concat(ROBUSTNESS_TEST.out.ch_vis)
    }

    if (params.final_model_on_full_data) {
        // we only do this for models, not for baselines
        ch_test_modes = channel.from(test_modes)
        ch_final_split = ch_models
                            .map{it -> it[0]}
                            .unique()
                            .combine(response_dataset)
                            .combine(ch_test_modes)
                            .combine(work_path)

        FINAL_SPLIT(
            ch_final_split
        )
        ch_versions = ch_versions.mix(FINAL_SPLIT.out.versions)

        ch_tune_final_model = ch_models
                            .combine(FINAL_SPLIT.out.final_datasets, by: 0)
                            .map { model_class, model_name, train_ds, val_ds, es_ds ->
                                [model_name, train_ds, val_ds, es_ds] }
                            .combine(ch_test_modes)
                            .combine(work_path)
                            .combine(ch_hpam_combis, by: 0)

        TUNE_FINAL_MODEL(
            ch_tune_final_model,
            params.response_transformation,
            params.model_checkpoint_dir,
            params.optim_metric
        )
        ch_versions = ch_versions.mix(TUNE_FINAL_MODEL.out.versions)
        ch_combined_hpams = TUNE_FINAL_MODEL.out.final_prediction.groupTuple(by: [0,1,2])

        EVALUATE_FIND_MAX_FINAL(
            ch_combined_hpams,
            params.optim_metric
        )
        ch_versions = ch_versions.mix(EVALUATE_FIND_MAX_FINAL.out.versions)
        ch_final_model = EVALUATE_FIND_MAX_FINAL.out.best_combis
                            .map{ model_name, final_constant, test_mode, best_hpam_combi ->
                                [model_name, test_mode, best_hpam_combi] }
                            .combine(FINAL_SPLIT.out.final_datasets, by: 0)
                            .combine(work_path)
        TRAIN_FINAL_MODEL (
            ch_final_model,
            params.model_checkpoint_dir
       )
       ch_versions = ch_versions.mix(TRAIN_FINAL_MODEL.out.versions)
    }

    ch_consolidate = ch_vis
                        .map{ test_mode, model, pred_file -> [test_mode, model.split("\\.")[0]] }
                        .unique()

    CONSOLIDATE_RESULTS (
        ch_consolidate,
        randomizations,
        ch_vis.count() // wait for ch_vis to finish
    )
    ch_versions = ch_versions.mix(CONSOLIDATE_RESULTS.out.versions)
    ch_consolidate = CONSOLIDATE_RESULTS.out.ch_vis.transpose()
    // filter out SingleDrugModels that have been consolidated
    ch_vis = ch_vis
                .concat(ch_consolidate)
                .transpose()
                .map{ test_mode, model, pred_file -> [model, test_mode, pred_file] }
                .combine(ch_models_baselines, by: 0)
                .map{ model, test_mode, pred_file -> [test_mode, model, pred_file] }

    EVALUATE_FINAL (
        ch_vis
    )
    ch_versions = ch_versions.mix(EVALUATE_FINAL.out.versions)

    ch_collapse = EVALUATE_FINAL.out.ch_individual_results.collect()

    COLLECT_RESULTS (
        ch_collapse,
        work_path
    )
    ch_versions = ch_versions.mix(COLLECT_RESULTS.out.versions)

    // evaluation_results_per_cl and evaluation_results_per_drug are optional
    evaluation_results_per_drug = COLLECT_RESULTS.out.evaluation_results_per_drug.ifEmpty(file("${projectDir}/assets/NO_FILE", checkIfExists: true))
    evaluation_results_per_cl = COLLECT_RESULTS.out.evaluation_results_per_cl.ifEmpty(file("${projectDir}/assets/NO_FILE", checkIfExists: true))
    ch_input_vis = COLLECT_RESULTS.out.evaluation_results.concat(
        evaluation_results_per_drug,
        evaluation_results_per_cl,
        COLLECT_RESULTS.out.true_vs_pred
    ).collect()

    VISUALIZE_RESULTS(
        ch_input_vis,
        work_path
    )
    ch_versions = ch_versions.mix(VISUALIZE_RESULTS.out.versions)

    emit:
    versions = ch_versions
}
