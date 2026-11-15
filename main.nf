#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-core/drugresponseeval
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/nf-core/drugresponseeval
    Website: https://nf-co.re/drugresponseeval
    Slack  : https://nfcore.slack.com/channels/drugresponseeval
----------------------------------------------------------------------------------------
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { DRUGRESPONSEEVAL  } from './workflows/drugresponseeval'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_drugresponseeval_pipeline'
include { PIPELINE_COMPLETION     } from './subworkflows/local/utils_nfcore_drugresponseeval_pipeline'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOWS FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Run main analysis pipeline depending on type of input
//
workflow NFCORE_DRUGRESPONSEEVAL {
    take:
    models                    // channel: model name/recipe strings from samplesheet
    normalization_reference   // val: baseline model name for reports
    dataset_file              // channel: [ string(dataset) ]
    dataset_name
    test_mode
    n_cv_splits
    measure
    no_hyperparameter_tuning
    optim_metric
    hpo_num_samples
    response_transformation

    main:

    //
    // WORKFLOW: Run pipeline
    //
    DRUGRESPONSEEVAL (
        models,
        normalization_reference,
        dataset_file,
        dataset_name,
        test_mode,
        n_cv_splits,
        measure,
        no_hyperparameter_tuning,
        optim_metric,
        hpo_num_samples,
        response_transformation
    )
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

params {
    // False by default (=refitting). By default, we use measures calculated with CurveCurator instead of original measures reported by the authors for the available datasets, or invoke automatic fitting of custom raw viability data with CurveCurator. Set this flag to disable this option.
    no_refitting: Boolean = false

    // Disable hyperparameter tuning.
    no_hyperparameter_tuning: Boolean = false

    // Train final model on full data.
    final_model_on_full_data: Boolean = false

    // Number of repeated trainings for the robustness test.
    n_trials_robustness: Integer = 0

    // Number of cross-validation splits.
    n_cv_splits: Integer = 10

    // Display version and exit.
    version: Boolean

    // Send plain-text email instead of HTML.
    plaintext_email: Boolean

    // Do not use coloured log outputs.
    monochrome_logs: Boolean

    // Boolean whether to validate parameters against the schema at runtime
    validate_params: Boolean = true

    // Display the full detailed help message.
    help_full: Boolean

    // Display hidden parameters in the help message (only works when --help or --help_full are provided).
    show_hidden: Boolean
}

workflow {

    main:
    //
    // SUBWORKFLOW: Run initialisation tasks
    //
    PIPELINE_INITIALISATION (
        params.version,
        params.validate_params,
        params.monochrome_logs,
        args,
        params.outdir,
        params.help,
        params.help_full,
        params.show_hidden
    )

    //
    // WORKFLOW: Run main workflow
    //
    NFCORE_DRUGRESPONSEEVAL (
        PIPELINE_INITIALISATION.out.samplesheet,
        params.normalization_reference,
        params.dataset_file,
        params.dataset_name,
        params.test_mode,
        params.n_cv_splits,
        params.measure,
        params.no_hyperparameter_tuning,
        params.optim_metric,
        params.hpo_num_samples,
        params.response_transformation
    )
    //
    // SUBWORKFLOW: Run completion tasks
    //
    PIPELINE_COMPLETION (
        params.email,
        params.email_on_fail,
        params.plaintext_email,
        params.outdir,
        params.monochrome_logs,
    )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
