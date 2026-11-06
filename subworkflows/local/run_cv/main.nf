include { UNZIP as UNZIP_RESPONSE              } from '../../../modules/nf-core/unzip/main'
include { UNZIP as UNZIP_CS_RESPONSE           } from '../../../modules/nf-core/unzip/main'
include { UNZIP as UNZIP_META                  } from '../../../modules/nf-core/unzip/main'
include { LOAD_RESPONSE as LOAD_RESPONSE       } from '../../../modules/local/load_response'
include { LOAD_RESPONSE as LOAD_CS_RESPONSE    } from '../../../modules/local/load_response'
include { CV_SPLIT                             } from '../../../modules/local/cv_split'
include { HPAM_SPLIT                           } from '../../../modules/local/hpam_split'
include { TRAIN_AND_PREDICT_CV                 } from '../../../modules/local/train_and_predict_cv'
include { EVALUATE_FIND_MAX                    } from '../../../modules/local/evaluate_find_max'
include { WRITE_BEST_HPAM                      } from '../../../modules/local/write_best_hpam'

workflow RUN_CV {
    take:
    test_modes                     // LPO,LDO,LCO, LTO
    ch_models                      // channel of model names for full testing
    ch_baselines                   // channel of model names for comparison
    work_path                      // path to data
    measure
    path_data
    dataset_name
    zenodo_link
    cross_study_dataset_names      // comma-separated string, '' if none
    clean_min_responders
    clean_min_responder_frac
    custom_splitter_path
    n_cv_splits
    no_hyperparameter_tuning
    response_transformation
    model_checkpoint_dir
    optim_metric

    main:
    ch_versions = channel.empty()
    File response_path = new File("${path_data}/${dataset_name}/${dataset_name}.csv")
    File meta_path = new File("${path_data}/meta/gene_lists/landmark_genes.csv")
    // The TOY meta has a landmark gene list with 13 genes (+ header), the real one has more.
    // Redownload if the meta on disk belongs to the other kind of dataset.
    def is_toy_dataset = dataset_name.startsWith('TOY')
    // TOY datasets are no longer on Zenodo, they always come from the nf-core test-datasets repository
    def toy_link = 'https://raw.githubusercontent.com/nf-core/test-datasets/refs/heads/drugresponseeval/test_data/'
    def data_link = is_toy_dataset ? toy_link : zenodo_link
    def meta_is_toy = meta_path.exists() ? meta_path.readLines().size() <= 14 : null
    if (meta_is_toy == null || meta_is_toy != is_toy_dataset) {
        log.info "Downloading meta information including gene lists from: ${data_link}meta.zip"
        ch_unzip_meta = channel
                            .fromPath("${data_link}meta.zip")
                            .map { file -> [[id:"meta"], file] }
        UNZIP_META(ch_unzip_meta)
    }
    if (!response_path.exists()) {
        log.info "Downloading response dataset ${dataset_name} from: ${data_link}${dataset_name}.zip"
        ch_unzip = channel
                        .fromPath("${data_link}${dataset_name}.zip")
                        .map { file -> [[id:dataset_name], file] }
        UNZIP_RESPONSE(ch_unzip)
        ch_response = UNZIP_RESPONSE.out.unzipped_csv
    } else {
        log.info "Using existing response dataset ${dataset_name} from ${response_path}"
        ch_response = channel.fromPath(response_path, checkIfExists: true)
    }

    if (cross_study_dataset_names != '') {
        def cross_study_datasets = cross_study_dataset_names.split(',')
        log.info "Using cross-study datasets: ${cross_study_datasets.join(', ')}"
        // iterate over cross-study datasets and load them
        ch_all_cs =             channel
                                .of(cross_study_datasets)
                                .map { cs_name -> [cs_name, file("${path_data}/${cs_name}/${cs_name}.csv")]}
        ch_cs_cached =          ch_all_cs
                                .filter { cs_name, dataset_path ->
                                    dataset_path.exists()
                                }
                                .map { cs_name, dataset_path ->
                                    file("${dataset_path}", checkIfExists: true)
                                }

        ch_cs_to_be_loaded =    ch_all_cs
                                .filter { cs_name, dataset_path ->
                                    !dataset_path.exists()
                                }
                                .map { cs_name, dataset_path ->
                                    [[id:cs_name], "${cs_name.startsWith('TOY') ? toy_link : zenodo_link}${dataset_path.baseName}.zip"]
                                }
        UNZIP_CS_RESPONSE(ch_cs_to_be_loaded)
        ch_cs_loaded = UNZIP_CS_RESPONSE.out.unzipped_csv
        ch_cross_study_datasets = ch_cs_cached.concat(ch_cs_loaded)
    } else {
        ch_cross_study_datasets = channel.empty()
    }

    ch_response = measure.combine(ch_response)
    ch_cross_study_datasets = measure.combine(ch_cross_study_datasets)
    LOAD_RESPONSE(ch_response, false, clean_min_responders ?: '', clean_min_responder_frac ?: '')
    LOAD_CS_RESPONSE(ch_cross_study_datasets, true, '', '')


    ch_test_modes = channel.from(test_modes)
    ch_data = ch_test_modes.combine(LOAD_RESPONSE.out.response_dataset)

    custom_splitter = custom_splitter_path
        ? file(custom_splitter_path, checkIfExists: true)
        : file("${projectDir}/assets/NO_FILE", checkIfExists: true)
    CV_SPLIT (
        ch_data,
        n_cv_splits,
        custom_splitter
    )
    // [test_mode, [split_1.pkl, split_2.pkl, ..., split_n.pkl]]
    ch_cv_splits = CV_SPLIT.out.response_cv_splits

    ch_models_baselines = ch_models.concat(ch_baselines)

    HPAM_SPLIT (
        ch_models_baselines,
        no_hyperparameter_tuning
    )
    // [model_name, hpam_X.yaml]
    ch_hpam_combis = HPAM_SPLIT.out.hpam_combi.transpose()

    // [model_name, test_mode, split_X.pkl]
    ch_model_cv = ch_models_baselines
        .combine(ch_cv_splits.transpose())
    // [model_name, test_mode, split_X.pkl, hpam_X.yaml]
    ch_test_combis = ch_model_cv.combine(ch_hpam_combis, by: 0)

    if (no_hyperparameter_tuning) {
        // only one hyperparameter combination: no need to train and evaluate it on the CV splits
        WRITE_BEST_HPAM (
            ch_test_combis.map { model_name, test_mode, split, hpam_yaml -> [model_name, test_mode, split.baseName, hpam_yaml] }
        )
        ch_best_combis = WRITE_BEST_HPAM.out.best_combis
    } else {
        // [model_name, test_mode, split_X.pkl, hpam_X.yaml, path/to/data]
        TRAIN_AND_PREDICT_CV(ch_test_combis.combine(work_path), response_transformation, model_checkpoint_dir)

        // [model_name, test_mode, split_id,
        // [hpam_0.yaml, hpam_1.yaml, ..., hpam_n.yaml],
        // [prediction_dataset_0.pkl, ..., prediction_dataset_n.pkl] ]
        ch_combined_hpams = TRAIN_AND_PREDICT_CV.out.pred_data.groupTuple(by: [0,1,2])

        EVALUATE_FIND_MAX (
            ch_combined_hpams,
            optim_metric
        )
        ch_best_combis = EVALUATE_FIND_MAX.out.best_combis
    }

    // [split_id, test_mode, split_dataset, model_name, best_hpam_combi_X.yaml]
    ch_best_hpams_per_split = ch_cv_splits
    .map { test_mode, it -> [it, it.baseName, test_mode]}
    .transpose()
    .combine(ch_best_combis, by: [1, 2])

    emit:
    best_hpam_per_split = ch_best_hpams_per_split
    response_dataset = LOAD_RESPONSE.out.response_dataset.collect()
    cross_study_datasets = LOAD_CS_RESPONSE.out.cross_study_datasets.collect()
    ch_hpam_combis = ch_hpam_combis
    versions = ch_versions
}
