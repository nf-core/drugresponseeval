include { LOAD_RESPONSE                     } from '../../../modules/local/load_response'
include { MAKE_MODEL_CHANNEL as MAKE_MODELS } from '../../../modules/local/make_model_channel'
include { MAKE_MODEL_CHANNEL as MAKE_BASELINES } from '../../../modules/local/make_model_channel'
include { CV_SPLIT                          } from '../../../modules/local/cv_split'
include { HPAM_SPLIT                        } from '../../../modules/local/hpam_split'
include { TRAIN_AND_PREDICT_CV              } from '../../../modules/local/train_and_predict_cv'
include { EVALUATE_FIND_MAX                 } from '../../../modules/local/evaluate_find_max'

workflow RUN_CV {
    take:
    test_modes                      // LPO,LDO,LCO
    models                          // model names for full testing
    baselines                        // model names for comparison
    work_path                      // path to data
    measure

    main:
    ch_versions = Channel.empty()
    LOAD_RESPONSE(params.dataset_name, work_path, params.cross_study_datasets, measure)
    ch_versions = ch_versions.mix(LOAD_RESPONSE.out.versions)

    ch_test_modes = channel.from(test_modes)
    ch_data = ch_test_modes.combine(LOAD_RESPONSE.out.response_dataset)

    CV_SPLIT (
        ch_data,
        params.n_cv_splits
    )
    ch_versions = ch_versions.mix(CV_SPLIT.out.versions)
    // [test_mode, [split_1.pkl, split_2.pkl, ..., split_n.pkl]]
    ch_cv_splits = CV_SPLIT.out.response_cv_splits

    ch_models = channel.from(models)
    ch_baselines = channel.from(baselines)
    ch_models_baselines = ch_models.concat(ch_baselines)
    ch_input_models = ch_models
                        .collect()
                        .map { models -> [models] }
                        .combine(LOAD_RESPONSE.out.response_dataset)
    ch_input_baselines = ch_baselines
                        .collect()
                        .map { models -> [models] }
                        .combine(LOAD_RESPONSE.out.response_dataset)

    MAKE_MODELS (
        ch_input_models,
        "models"
    )
    ch_versions = ch_versions.mix(MAKE_MODELS.out.versions)

    MAKE_BASELINES (
        ch_input_baselines,
        "baselines"
    )
    ch_versions = ch_versions.mix(MAKE_BASELINES.out.versions)

    ch_models_expanded = MAKE_MODELS.out.all_models
                        .splitCsv(strip: true)
    ch_baselines_expanded = MAKE_BASELINES.out.all_models
                        .splitCsv(strip: true)
    ch_models_baselines_expanded = ch_models_expanded.concat(ch_baselines_expanded)

    HPAM_SPLIT (
        ch_models_baselines
    )
    ch_versions = ch_versions.mix(HPAM_SPLIT.out.versions)
    // [model_name, [hpam_0.yaml, hpam_1.yaml, ..., hpam_n.yaml]]
    ch_hpam_combis = ch_models_baselines_expanded
        .combine(HPAM_SPLIT.out.hpam_combi, by: 0)
        .map { model_class, model_name, hpam_combis -> [model_name, hpam_combis] }

    // [model_name, hpam_X.yaml]
    ch_hpam_combis = ch_hpam_combis.transpose()

    // [model_name, test_mode, split_X.pkl]
    ch_model_cv = ch_models_baselines_expanded
        .combine(ch_cv_splits.transpose())
        .map { model_class, model_name, test_mode, split -> [model_name, test_mode, split] }
    // [model_name, test_mode, split_X.pkl, hpam_X.yaml, path/to/data]
    ch_test_combis = ch_model_cv.combine(ch_hpam_combis, by: 0)
    ch_test_combis = ch_test_combis.combine(work_path)

    TRAIN_AND_PREDICT_CV(ch_test_combis, params.response_transformation, params.model_checkpoint_dir)
    ch_versions = ch_versions.mix(TRAIN_AND_PREDICT_CV.out.versions)

    // [model_name, test_mode, split_id,
    // [hpam_0.yaml, hpam_1.yaml, ..., hpam_n.yaml],
    // [prediction_dataset_0.pkl, ..., prediction_dataset_n.pkl] ]
    ch_combined_hpams = TRAIN_AND_PREDICT_CV.out.pred_data.groupTuple(by: [0,1,2])

    EVALUATE_FIND_MAX (
        ch_combined_hpams,
        params.optim_metric
    )
    ch_versions = ch_versions.mix(EVALUATE_FIND_MAX.out.versions)

    // [split_id, test_mode, split_dataset, model_name, best_hpam_combi_X.yaml]
    ch_best_hpams_per_split = ch_cv_splits
    .map { test_mode, it -> [it, it.baseName, test_mode]}
    .transpose()
    .combine(EVALUATE_FIND_MAX.out.best_combis, by: [1, 2])

    emit:
    best_hpam_per_split = ch_best_hpams_per_split
    cross_study_datasets = LOAD_RESPONSE.out.cross_study_datasets
    ch_models = MAKE_MODELS.out.all_models.splitCsv(strip: true)
    versions = ch_versions
}
