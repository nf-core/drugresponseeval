include { PREDICT_FULL                  } from '../../../modules/local/predict_full'
include { RANDOMIZATION_SPLIT           } from '../../../modules/local/randomization_split'
include { RANDOMIZATION_TEST            } from '../../../modules/local/randomization_test'
include { ROBUSTNESS_TEST               } from '../../../modules/local/robustness_test'
include { CONSOLIDATE_RESULTS           } from '../../../modules/local/consolidate_results'
include { EVALUATE_FINAL                } from '../../../modules/local/evaluate_final'
include { COLLECT_RESULTS               } from '../../../modules/local/collect_results'


workflow MODEL_TESTING {
    take:
    ch_models_baselines         // from input
    best_hpam_per_split         // from RUN_CV: [split_id, test_mode, split_dataset, model_name, best_hpam_combi_X.yaml]
    randomizations              // from input
    cross_study_datasets        // from LOAD_RESPONSE
    ch_models                  // from RUN_CV
    work_path                  // from input

    main:
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
    ch_vis = PREDICT_FULL.out.ch_vis

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
        ch_rand_views = ch_models
                        .combine(RANDOMIZATION_SPLIT.out.randomization_test_views, by: 0)
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
        ch_vis = ch_vis.concat(ROBUSTNESS_TEST.out.ch_vis)
    }

    ch_consolidate = ch_vis
                        .map{ test_mode, model, pred_file -> [test_mode, model.split("\\.")[0]] }
                        .unique()

    CONSOLIDATE_RESULTS (
        ch_consolidate,
        randomizations,
        ch_vis.count() // wait for ch_vis to finish
    )
    CONSOLIDATE_RESULTS.out.ch_vis.transpose()

    // filter out SingleDrugModels that have been consolidated
    ch_vis = ch_vis
                .concat(CONSOLIDATE_RESULTS.out.ch_vis.transpose())
                .map{ test_mode, model, pred_file -> [model, test_mode, pred_file] }
                .combine(ch_models_baselines, by: 0)
                .map{ model, test_mode, pred_file -> [test_mode, model, pred_file] }

    EVALUATE_FINAL (
        ch_vis
    )

    ch_collapse = EVALUATE_FINAL.out.ch_individual_results.collect()

    COLLECT_RESULTS (
        ch_collapse
    )

    emit:
    evaluation_results = COLLECT_RESULTS.out.evaluation_results
    evaluation_results_per_drug = COLLECT_RESULTS.out.evaluation_results_per_drug
    evaluation_results_per_cl = COLLECT_RESULTS.out.evaluation_results_per_cl
    true_vs_predicted = COLLECT_RESULTS.out.true_vs_pred
}
