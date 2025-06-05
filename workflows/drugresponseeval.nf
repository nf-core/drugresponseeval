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

def test_modes = params.test_mode.split(",")
def randomizations = params.randomization_mode.split(",")

workflow DRUGRESPONSEEVAL {

    take:
    models          // channel: [ string(models) ]
    baselines       // channel: [ string(baselines) ]
    work_path       // channel: path to the data channel.fromPath(params.path_data)

    main:
    ch_versions = Channel.empty()

    //
    // Collate and save software versions
    //
    //softwareVersionsToYAML(ch_versions)
    //    .collectFile(
    //        storeDir: "${params.outdir}/pipeline_info",
    //        name: 'nf_core_'  +  'drugresponseeval_software_'  + 'versions.yml',
    //        sort: true,
    //        newLine: true
    //    ).set { ch_collated_versions }

    ch_models_baselines = models.concat(baselines)

    PREPROCESS_CUSTOM (
        work_path,
        params.dataset_name,
        params.measure
    )
    ch_versions = ch_versions.mix(PREPROCESS_CUSTOM.out.versions)

    RUN_CV (
        test_modes,
        models,
        baselines,
        work_path,
        PREPROCESS_CUSTOM.out.measure
    )
    ch_versions = ch_versions.mix(RUN_CV.out.versions)

    MODEL_TESTING (
        ch_models_baselines,
        RUN_CV.out.best_hpam_per_split,
        randomizations,
        RUN_CV.out.cross_study_datasets,
        RUN_CV.out.ch_models,
        work_path
    )
    ch_versions = ch_versions.mix(MODEL_TESTING.out.versions)

    emit:
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
