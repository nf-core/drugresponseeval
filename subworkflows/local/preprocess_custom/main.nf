include { FIT_CURVES                        } from '../../../modules/local/fit_curves'
include { PREPROCESS_RAW_VIABILITY          } from '../../../modules/local/preprocess_raw_viability'
include { POSTPROCESS_CURVECURATOR_DATA     } from '../../../modules/local/postprocess_curvecurator_output'

workflow PREPROCESS_CUSTOM {
    take:
    path_data
    dataset_name
    measure

    main:
    File raw_file = new File("${params.path_data}/${dataset_name}/${dataset_name}_raw.csv")

    if (raw_file.exists()){
        PREPROCESS_RAW_VIABILITY(dataset_name, path_data)
        FIT_CURVES(dataset_name, PREPROCESS_RAW_VIABILITY.out.path_to_toml, PREPROCESS_RAW_VIABILITY.out.curvecurator_input)
        POSTPROCESS_CURVECURATOR_DATA(dataset_name, FIT_CURVES.out.path_to_curvecurator_out, measure)
    }
    emit:
    measure = POSTPROCESS_CURVECURATOR_DATA.out.measure
}
