include { PREDICT_FULL                                  } from '../../../modules/local/predict_full'
include { RANDOMIZATION_SPLIT                           } from '../../../modules/local/randomization_split'
include { RANDOMIZATION_TEST                            } from '../../../modules/local/randomization_test'
include { ROBUSTNESS_TEST                               } from '../../../modules/local/robustness_test'
include { FINAL_SPLIT                                   } from '../../../modules/local/final_split'
include { TUNE_FINAL_MODEL                              } from '../../../modules/local/tune_final_model'
include { EVALUATE_FIND_MAX as EVALUATE_FIND_MAX_FINAL  } from '../../../modules/local/evaluate_find_max'
include { TRAIN_FINAL_MODEL                             } from '../../../modules/local/train_final_model'
include { EVALUATE_FINAL                                } from '../../../modules/local/evaluate_final'
include { COLLECT_RESULTS                               } from '../../../modules/local/collect_results'
include { VISUALIZE_RESULTS                             } from '../../../modules/local/visualize_results'


workflow MODEL_TESTING {
    take:
    ch_models_baselines         // from input: model and baseline names
    best_hpam_per_split         // from RUN_CV: [split_id, test_mode, split_dataset, model_name, best_hpam_combi_X.yaml]
    randomizations              // from input
    response_dataset            // from LOAD_RESPONSE
    cross_study_datasets        // from LOAD_RESPONSE
    ch_models                  // from RUN_CV: model names
    work_path                  // from input
    test_modes                 // e.g., ['LPO', 'LCO']
    ch_hpam_combis              // from RUN_CV [model_name, hpam_X.yaml]

    main:
    ch_versions = channel.empty()
    if (params.cross_study_datasets == '') {
        cross_study_datasets = channel.of(file("${projectDir}/assets/NONE.csv", checkIfExists: true))
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
    ch_vis = PREDICT_FULL.out.ch_vis.concat(PREDICT_FULL.out.ch_cross)

    if (params.randomization_mode != 'None') {
        ch_randomization = channel.from(randomizations)
        // randomizations only for models, not for baselines
        ch_models_rand = ch_models
                            .combine(ch_randomization)
        RANDOMIZATION_SPLIT (
            ch_models_rand
        )
        // [model_name, randomization_test_view_X.yaml]
        ch_rand_views = RANDOMIZATION_SPLIT.out.randomization_test_views.transpose()

        ch_best_hpams_per_split_rand = best_hpam_per_split.map {
            split_id, test_mode, path_to_split, model_name, path_to_hpams ->
            return [model_name, test_mode, split_id, path_to_split, path_to_hpams]
        }
        // [model_name, test_mode, split_id, split_dataset, best_hpam_combi_X.yaml,
        // randomization_views]
        ch_randomization = ch_best_hpams_per_split_rand
                            .combine(ch_rand_views, by: 0)
                            .combine(work_path)
                            .filter { model_name, test_mode, split_id, split_dataset, best_hpams, randomization_views, path_data ->
                                def yaml = new org.yaml.snakeyaml.Yaml()
                                def hpam_data = yaml.load(best_hpams.text)
                                def best = hpam_data[hpam_data.keySet().first()]
                                // single drug models have one best hyperparameter combination per drug
                                def best_hpams_list = best.containsKey("best_hpam_combi_per_drug") ? best["best_hpam_combi_per_drug"].values() : [best["best_hpam_combi"]]
                                def all_views = best_hpams_list.collectMany { best_hpam ->
                                    def cl_views  = best_hpam["cell_line_views"]
                                    def dr_views  = best_hpam["drug_views"]
                                    if (cl_views instanceof String)  cl_views  = [cl_views]
                                    if (dr_views instanceof String)  dr_views  = [dr_views]
                                    (cl_views ?: []) + (dr_views ?: [])
                                }.unique()
                                def rand_data = yaml.load(randomization_views.text)
                                def view      = rand_data["view"]
                                def keep = all_views.contains(view)
                                if (!keep) {
                                    log.info "Skipping randomization test: view '${view}' not in model views ${all_views} for ${model_name} ${split_id}"
                                }
                                return keep
                            }

        RANDOMIZATION_TEST (
            ch_randomization,
            params.randomization_type,
            params.response_transformation,
            params.model_checkpoint_dir
        )
        ch_vis = ch_vis.concat(RANDOMIZATION_TEST.out.ch_vis)
    }

    if (params.n_trials_robustness > 0) {
        ch_trials_robustness = channel.from(1..params.n_trials_robustness)
        ch_trials_robustness = ch_models
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
            params.response_transformation,
            params.model_checkpoint_dir
        )
        ch_vis = ch_vis.concat(ROBUSTNESS_TEST.out.ch_vis)
    }

    if (params.final_model_on_full_data) {
        // we only do this for models, not for baselines
        ch_test_modes = channel.from(test_modes)
        ch_final_split = ch_models
                            .combine(response_dataset)
                            .combine(ch_test_modes)
                            .combine(work_path)

        FINAL_SPLIT(
            ch_final_split
        )

        ch_tune_final_model = ch_models
                            .combine(FINAL_SPLIT.out.final_datasets, by: 0)
                            .combine(ch_test_modes)
                            .combine(work_path)
                            .combine(ch_hpam_combis, by: 0)

        TUNE_FINAL_MODEL(
            ch_tune_final_model,
            params.response_transformation,
            params.model_checkpoint_dir
        )
        ch_combined_hpams = TUNE_FINAL_MODEL.out.final_prediction.groupTuple(by: [0,1,2])

        EVALUATE_FIND_MAX_FINAL(
            ch_combined_hpams,
            params.optim_metric
        )
        ch_final_model = EVALUATE_FIND_MAX_FINAL.out.best_combis
                            .map{ model_name, final_constant, test_mode, best_hpam_combi ->
                                [model_name, test_mode, best_hpam_combi] }
                            .combine(FINAL_SPLIT.out.final_datasets, by: 0)
                            .combine(work_path)
        TRAIN_FINAL_MODEL (
            ch_final_model,
            params.response_transformation,
            params.model_checkpoint_dir
       )
    }

    ch_vis = ch_vis
                .transpose()
                .map{ test_mode, model, pred_file -> [model, test_mode, pred_file] }
                .combine(ch_models_baselines, by: 0)
                .map{ model, test_mode, pred_file -> [test_mode, model, pred_file] }

    EVALUATE_FINAL (
        ch_vis
    )

    ch_collapse = EVALUATE_FINAL.out.ch_individual_results.collect()

    COLLECT_RESULTS (
        ch_collapse,
        work_path
    )

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

    emit:
    versions = ch_versions
}
