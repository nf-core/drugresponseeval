include { UNZIP as UNZIP_RESPONSE           } from '../../../modules/local/unzip'
include { UNZIP as UNZIP_CS_RESPONSE        } from '../../../modules/local/unzip'
include { LOAD_RESPONSE as LOAD_RESPONSE    } from '../../../modules/local/load_response'
include { LOAD_RESPONSE as LOAD_CS_RESPONSE } from '../../../modules/local/load_response'
include { MAKE_MODEL_CHANNEL as MAKE_MODELS } from '../../../modules/local/make_model_channel'
include { MAKE_MODEL_CHANNEL as MAKE_BASELINES } from '../../../modules/local/make_model_channel'
include { CV_SPLIT                          } from '../../../modules/local/cv_split'
include { HPAM_SPLIT                        } from '../../../modules/local/hpam_split'
include { TRAIN_AND_PREDICT_CV              } from '../../../modules/local/train_and_predict_cv'
include { EVALUATE_FIND_MAX                 } from '../../../modules/local/evaluate_find_max'

workflow RUN_CV {
    take:
    test_modes                      // LPO,LDO,LCO, LTO
    ch_models                      // channel of model names for full testing
    ch_baselines                   // channel of model names for comparison
    work_path                      // path to data
    measure

    main:
    ch_versions = Channel.empty()
    File response_path = new File("${params.path_data}/${params.dataset_name}/${params.dataset_name}.csv")
    if (!response_path.exists()) {
        log.info "Downloading response dataset ${params.dataset_name} from Zenodo: ${params.zenodo_link}${params.dataset_name}.zip"
        ch_unzip = channel
                        .fromPath("${params.zenodo_link}${params.dataset_name}.zip")
                        .map { file -> [params.dataset_name, file] }
        UNZIP_RESPONSE(ch_unzip)
        ch_versions = ch_versions.mix(UNZIP_RESPONSE.out.versions)
        ch_response = UNZIP_RESPONSE.out.unzipped_archive
                        .map { dataset_name, path_to_dir, response_file ->
                            file(response_file, checkIfExists: true)
                        }
    }else{
        log.info "Using existing response dataset ${params.dataset_name} from ${response_path}"
        ch_response = channel.fromPath(response_path, checkIfExists: true)
    }

    if (params.cross_study_datasets != '') {
        def cross_study_datasets = params.cross_study_datasets.split(',')
        log.info "Using cross-study datasets: ${cross_study_datasets.join(', ')}"
        // iterate over cross-study datasets and load them
        ch_all_cs =             channel
                                .of(cross_study_datasets)
                                .map { dataset_name -> [dataset_name, file("${params.path_data}/${dataset_name}/${dataset_name}.csv")]}
        ch_cs_cached =          ch_all_cs
                                .filter { dataset_name, dataset_path ->
                                    dataset_path.exists()
                                }
                                .map { dataset_name, dataset_path ->
                                    file("${dataset_path}", checkIfExists: true)
                                }

        ch_cs_to_be_loaded =    ch_all_cs
                                .filter { dataset_name, dataset_path ->
                                    !dataset_path.exists()
                                }
                                .map { dataset_name, dataset_path ->
                                    [dataset_name, "${params.zenodo_link}${dataset_path.baseName}.zip"]
                                }
        UNZIP_CS_RESPONSE(ch_cs_to_be_loaded)
        ch_versions = ch_versions.mix(UNZIP_CS_RESPONSE.out.versions)
        ch_cs_loaded = UNZIP_CS_RESPONSE.out.unzipped_archive
                        .map { dataset_name, path_to_dir, response_file ->
                            file(response_file, checkIfExists: true)
                        }
        ch_cross_study_datasets = ch_cs_cached.concat(ch_cs_loaded)
    } else {
        ch_cross_study_datasets = channel.empty()
    }
    ch_response = measure.combine(ch_response)
    ch_cross_study_datasets = measure.combine(ch_cross_study_datasets)
    LOAD_RESPONSE(ch_response, false)
    ch_versions = ch_versions.mix(LOAD_RESPONSE.out.versions)
    LOAD_CS_RESPONSE(ch_cross_study_datasets, true)
    ch_versions = ch_versions.mix(LOAD_CS_RESPONSE.out.versions)


    ch_test_modes = channel.from(test_modes)
    ch_data = ch_test_modes.combine(LOAD_RESPONSE.out.response_dataset)

    CV_SPLIT (
        ch_data,
        params.n_cv_splits
    )
    ch_versions = ch_versions.mix(CV_SPLIT.out.versions)
    // [test_mode, [split_1.pkl, split_2.pkl, ..., split_n.pkl]]
    ch_cv_splits = CV_SPLIT.out.response_cv_splits

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
        ch_models_baselines,
        params.no_hyperparameter_tuning
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
    response_dataset = LOAD_RESPONSE.out.response_dataset.collect()
    cross_study_datasets = LOAD_CS_RESPONSE.out.cross_study_datasets.collect()
    ch_models = MAKE_MODELS.out.all_models.splitCsv(strip: true)
    ch_hpam_combis = ch_hpam_combis
    versions = ch_versions
}
