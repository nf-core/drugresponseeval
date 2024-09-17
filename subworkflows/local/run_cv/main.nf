include { LOAD_RESPONSE                     } from '../../../modules/local/load_response'
include { MAKE_MODEL_CHANNEL                } from '../../../modules/local/make_model_channel'
include { CV_SPLIT                          } from '../../../modules/local/cv_split'
include { HPAM_SPLIT                        } from '../../../modules/local/hpam_split'
include { TRAIN_AND_PREDICT_CV              } from '../../../modules/local/train_and_predict_cv'
include { EVALUATE_FIND_MAX                 } from '../../../modules/local/evaluate_find_max'

workflow RUN_CV {
    take:
    test_modes                      // LPO,LDO,LCO
    models                          // model names for full testing
    baselines                        // model names for comparison

    main:
    LOAD_RESPONSE(params.dataset_name, params.path_data, params.cross_study_datasets)

    ch_test_modes = channel.from(test_modes)
    ch_data = ch_test_modes.combine(LOAD_RESPONSE.out.response_dataset)

    CV_SPLIT (
        ch_data,
        params.n_cv_splits
    )
    // [test_mode, [split_1.pkl, split_2.pkl, ..., split_n.pkl]]
    ch_cv_splits = CV_SPLIT.out.response_cv_splits

    ch_models = channel.from(models)
    ch_baselines = channel.from(baselines)
    ch_models_baselines = ch_models.concat(ch_baselines)
    if (params.cross_study_datasets) {
        all_data = LOAD_RESPONSE.out.response_dataset
                    .combine(LOAD_RESPONSE.out.cross_study_datasets)
    } else {
        all_data = LOAD_RESPONSE.out.response_dataset
    }
    all_data = all_data.flatten()
    ch_input_models = ch_models_baselines
                        .collect()
                        .map { models -> [models] }
                        .combine(all_data)

    MAKE_MODEL_CHANNEL (
        ch_input_models
    )

    ch_models_baselines = MAKE_MODEL_CHANNEL.out.all_models
                        .splitCsv(strip: true)
                        .flatten()

    HPAM_SPLIT (
        ch_models_baselines
    )

    // [model_name, [hpam_0.yaml, hpam_1.yaml, ..., hpam_n.yaml]]
    ch_hpam_combis = HPAM_SPLIT.out.hpam_combi
    // [model_name, hpam_X.yaml]
    ch_hpam_combis = ch_hpam_combis.transpose()

    // [model_name, test_mode, split_X.pkl]
    ch_model_cv = ch_models_baselines.combine(ch_cv_splits.transpose())

    // [model_name, test_mode, split_X.pkl, hpam_X.yaml]
    ch_test_combis = ch_model_cv.combine(ch_hpam_combis, by: 0)

    TRAIN_AND_PREDICT_CV (
        ch_test_combis,
        params.path_data,
        params.response_transformation
    )
    // [model_name, test_mode, split_id,
    // [hpam_0.yaml, hpam_1.yaml, ..., hpam_n.yaml],
    // [prediction_dataset_0.pkl, ..., prediction_dataset_n.pkl] ]
    ch_combined_hpams = TRAIN_AND_PREDICT_CV.out.groupTuple(by: [0,1,2])
    //ch_combined_hpams.view()

    EVALUATE_FIND_MAX (
        ch_combined_hpams,
        params.optim_metric
    )

    // [split_id, test_mode, split_dataset, model_name, best_hpam_combi_X.yaml]
    ch_best_hpams_per_split = ch_cv_splits
    .map { test_mode, it -> [it, it.baseName, test_mode]}
    .transpose()
    .combine(EVALUATE_FIND_MAX.out.best_combis, by: [1, 2])

    emit:
    best_hpam_per_split = ch_best_hpams_per_split
    cross_study_datasets = LOAD_RESPONSE.out.cross_study_datasets

}
