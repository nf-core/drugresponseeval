/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap } from 'plugin/nf-validation'

def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

WorkflowDrugresponseeval.initialise(params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { PARAMS_CHECK } from '../modules/local/params_check'
include { LOAD_RESPONSE } from '../modules/local/load_response'
include { CV_SPLIT } from '../modules/local/cv_split'
include { HPAM_SPLIT } from '../modules/local/hpam_split'
include { TRAIN_AND_PREDICT_CV } from '../modules/local/train_and_predict_cv'
//include { TRAIN_AND_PREDICT } from '../modules/local/train_and_predict'
include { EVALUATE } from '../modules/local/evaluate'
//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def models = params.models.split(",")

workflow DRUGRESPONSEEVAL {

    ch_versions = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //

    ch_models = channel.from(models)

    /*PARAMS_CHECK (
        params.models,
        params.test_mode,
        params.dataset_name,
        params.n_cv_splits,
        params.randomization_mode,
        params.curve_curator,
        params.response_transformation,
        params.optim_metric
    )*/

    LOAD_RESPONSE(params.dataset_name, params.path_data)

    CV_SPLIT (
        LOAD_RESPONSE.out.response_dataset,
        params.n_cv_splits,
        params.test_mode
    )
    ch_cv_splits = CV_SPLIT.out.response_cv_splits

    HPAM_SPLIT (
        ch_models
    )

    ch_hpam_combis = HPAM_SPLIT.out.hpam_combi
    ch_model_cv = ch_models.combine(ch_cv_splits.flatten())
    ch_hpam_combis = ch_hpam_combis.transpose()

    ch_test_combis = ch_model_cv.combine(ch_hpam_combis, by: 0)

    TRAIN_AND_PREDICT_CV (
        ch_test_combis,
        params.path_data,
        params.test_mode,
        params.response_transformation
    )

    EVALUATE (
        TRAIN_AND_PREDICT_CV.out.pred_data,
        params.optim_metric
    )


/*
    TRAIN_AND_PREDICT (
        params.model_name,
        params.hyperparameters,
        params.train_data,
        params.prediction_data,
        params.early_stopping_data,
        params.response_transformation,
        params.cl_features,
        params.drug_features
    )
*/
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
