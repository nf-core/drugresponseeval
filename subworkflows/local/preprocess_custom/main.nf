include { FIT_CURVES                        } from '../../../modules/local/fit_curves'
include { PREPROCESS_RAW_VIABILITY          } from '../../../modules/local/preprocess_raw_viability'
include { POSTPROCESS_CURVECURATOR_DATA     } from '../../../modules/local/postprocess_curvecurator_output'

workflow PREPROCESS_CUSTOM {
    take:
    work_path
    dataset_name
    measure

    main:

    def preimplemented_datasets = ['GDSC1', 'GDSC2', 'CCLE', 'CTRPv1', 'CTRPv2', 'TOYv1', 'TOYv2']
    if(!params.no_refitting){
        File raw_file = new File("${params.path_data}/${dataset_name}/${dataset_name}_raw.csv")
        // refit with CurveCurator or use measures refitted with CurveCurator
        if (dataset_name in preimplemented_datasets) {
            // the dataset was already fit, use the pre-fitted curves and derived measure
            ch_measure = channel.of("${measure}" + "_curvecurator")
        } else {
            log.info "Using a custom dataset: ${dataset_name}. If you want to use a pre-fitted dataset, please use one of the following: ${preimplemented_datasets.join(', ')}."
            // the dataset is not pre-fitted, we need to refit it
            if(!raw_file.exists()){
                throw new Exception("Raw data file not found: ${raw_file}. You want to refit a custom dataset with CurveCurator which requires raw viability data to be located at ${raw_file} but the file does not exist. Please provide the raw data in the correct format or set `no_refitting` to true in your parameters.")
            }else{
                PREPROCESS_RAW_VIABILITY(dataset_name, work_path)
                ch_toml_files = PREPROCESS_RAW_VIABILITY.out.path_to_toml
                                .flatten()
                                .map { file -> [file.parent.name, file] }
                ch_curvecurator_input = PREPROCESS_RAW_VIABILITY.out.curvecurator_input
                                        .flatten()
                                        .map { file -> [file.parent.name, file] }
                // [dose_dir_name, config.toml, curvecurator_input.tsv]
                ch_fit_curves = ch_toml_files.combine(ch_curvecurator_input, by: 0)
                FIT_CURVES(dataset_name, ch_fit_curves)
                ch_curves = FIT_CURVES.out.path_to_curvecurator_out.collect()
                POSTPROCESS_CURVECURATOR_DATA(dataset_name, ch_curves, measure)
                ch_measure = POSTPROCESS_CURVECURATOR_DATA.out.measure
            }
        }
    }else{
        log.warn "You have set `no_refitting` to true. We discourage this option for comparability to our pre-supplied datasets. If you want to use a custom dataset, please ensure it is processed in the correct format."
        File processed_file = new File("${params.path_data}/${dataset_name}/${dataset_name}.csv")
        if(dataset_name !in preimplemented_datasets){
            if (!processed_file.exists()){
                throw new Exception("Processed data file not found: ${processed_file}. You want to use a custom dataset but the file does not exist. Please provide the processed data in the correct format or set `no_refitting` to false in your parameters.")
            }
        }
        ch_measure = measure
    }
    emit:
    measure = ch_measure
}
