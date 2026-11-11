/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_drugresponseeval_pipeline'

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//

include { PREPROCESS_CUSTOM } from '../subworkflows/local/preprocess_custom'
include { RUN_CV } from '../subworkflows/local/run_cv'
include { MODEL_TESTING } from '../subworkflows/local/model_testing'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow DRUGRESPONSEEVAL {

    take:
    models          // channel: [ string(models) ]
    baselines       // channel: [ string(baselines) ]
    work_path       // channel: path to the data channel.fromPath(params.path_data)
    outdir
    path_data
    dataset_name
    measure
    no_refitting
    test_mode
    zenodo_link
    cross_study_datasets
    clean_min_responders
    clean_min_responder_frac
    custom_splitter_path
    n_cv_splits
    no_hyperparameter_tuning
    response_transformation
    model_checkpoint_dir
    optim_metric
    randomization_mode
    randomization_type
    n_trials_robustness
    final_model_on_full_data

    main:

    def ch_versions = channel.empty()

    PREPROCESS_CUSTOM (
        work_path,
        dataset_name,
        measure,
        no_refitting,
        path_data
    )
    ch_versions = ch_versions.mix(PREPROCESS_CUSTOM.out.versions)

    test_modes = test_mode.split(",")
    randomizations = randomization_mode.split(",")

    RUN_CV (
        test_modes,
        models,
        baselines,
        work_path,
        PREPROCESS_CUSTOM.out.measure,
        path_data,
        dataset_name,
        zenodo_link,
        cross_study_datasets,
        clean_min_responders,
        clean_min_responder_frac,
        custom_splitter_path,
        n_cv_splits,
        no_hyperparameter_tuning,
        response_transformation,
        model_checkpoint_dir,
        optim_metric
    )
    ch_versions = ch_versions.mix(RUN_CV.out.versions)

    MODEL_TESTING (
        RUN_CV.out.best_hpam_per_split,
        randomizations,
        RUN_CV.out.response_dataset,
        RUN_CV.out.cross_study_datasets,
        models,
        RUN_CV.out.work_path,
        test_modes,
        RUN_CV.out.ch_hpam_combis,
        cross_study_datasets,
        randomization_mode,
        randomization_type,
        n_trials_robustness,
        final_model_on_full_data,
        no_hyperparameter_tuning,
        response_transformation,
        model_checkpoint_dir,
        optim_metric
    )
    ch_versions = ch_versions.mix(MODEL_TESTING.out.versions)

    //
    // Collate and save software versions
    //
    def topic_versions = channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
        }
        .groupTuple(by:0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    def ch_collated_versions = softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${outdir}/pipeline_info",
            name: 'nf_core_'  +  'drugresponseeval_software_'  + 'versions.yml',
            sort: true,
            newLine: true
        )
    emit:
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
