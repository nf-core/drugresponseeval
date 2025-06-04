include { FIT_CURVES                        } from '../../../modules/local/fit_curves'
include { PREPROCESS_RAW_VIABILITY          } from '../../../modules/local/preprocess_raw_viability'
include { POSTPROCESS_CURVECURATOR_DATA     } from '../../../modules/local/postprocess_curvecurator_output'

workflow PREPROCESS_CUSTOM {
    take:
    work_path
    dataset_name
    measure

    main:
    ch_versions = Channel.empty()
    File raw_file = new File("${params.path_data}/${dataset_name}/${dataset_name}_raw.csv")

    if (raw_file.exists()){
        PREPROCESS_RAW_VIABILITY(dataset_name, work_path)
        ch_versions = ch_versions.mix(PREPROCESS_RAW_VIABILITY.out.versions)
        ch_toml_files = PREPROCESS_RAW_VIABILITY.out.path_to_toml
                        .flatten()
                        .map { file -> [file.parent.name, file] }
        ch_curvecurator_input = PREPROCESS_RAW_VIABILITY.out.curvecurator_input
                                .flatten()
                                .map { file -> [file.parent.name, file] }
        // [dose_dir_name, config.toml, curvecurator_input.tsv]
        ch_fit_curves = ch_toml_files.combine(ch_curvecurator_input, by: 0)
        FIT_CURVES(dataset_name, ch_fit_curves)
        ch_versions = ch_versions.mix(FIT_CURVES.out.versions)
        ch_curves = FIT_CURVES.out.path_to_curvecurator_out.collect()
        POSTPROCESS_CURVECURATOR_DATA(dataset_name, ch_curves, measure)
        ch_versions = ch_versions.mix(POSTPROCESS_CURVECURATOR_DATA.out.versions)
        ch_measure = POSTPROCESS_CURVECURATOR_DATA.out.measure
    }else if(params.curve_curator){
        ch_measure = Channel.of("${measure}" + "_curvecurator")
    }else{
        ch_measure = measure
    }
    emit:
    measure = ch_measure
    versions = ch_versions
}
