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
include { EVALUATE_FIND_MAX } from '../modules/local/evaluate_find_max'
include { PREDICT_FULL } from '../modules/local/predict_full'
include { RANDOMIZATION_SPLIT } from '../modules/local/randomization_split'
include { RANDOMIZATION_TEST } from '../modules/local/randomization_test'
include { ROBUSTNESS_TEST } from '../modules/local/robustness_test'
include { EVALUATE_FINAL } from '../modules/local/evaluate_final'
include { COLLECT_RESULTS } from '../modules/local/collect_results'
include { DRAW_VIOLIN } from '../modules/local/draw_violin'
include { DRAW_HEATMAP } from '../modules/local/draw_heatmap'
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

def test_modes = params.test_mode.split(",")
def models = params.models.split(",")
def baselines = params.baselines.split(",")
def randomizations = params.randomization_mode.split(",")
def outdirPath = new File(params.outdir).getAbsolutePath()

workflow DRUGRESPONSEEVAL {

    ch_versions = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    ch_test_modes = channel.from(test_modes)
    ch_models = channel.from(models)
    ch_baselines = channel.from(baselines)
    ch_models_baselines = ch_models.concat(ch_baselines)

    PARAMS_CHECK (
        params.baselines,
        params.models,
        params.test_mode,
        params.dataset_name,
        params.n_cv_splits,
        params.randomization_mode,
        params.curve_curator,
        params.response_transformation,
        params.optim_metric
    )

    LOAD_RESPONSE(params.dataset_name, params.path_data)

    ch_data = ch_test_modes.combine(LOAD_RESPONSE.out.response_dataset)

    CV_SPLIT (
        ch_data,
        params.n_cv_splits
    )
    // [test_mode, [split_1.pkl, split_2.pkl, ..., split_n.pkl]]
    ch_cv_splits = CV_SPLIT.out.response_cv_splits

    HPAM_SPLIT (
        ch_models_baselines
    )

    // [model_name, [hpam_0.yaml, hpam_1.yaml, ..., hpam_n.yaml]]
    ch_hpam_combis = HPAM_SPLIT.out.hpam_combi
    // [model_name, hpam_X.yaml]
    ch_hpam_combis = ch_hpam_combis.transpose()

    // [model_name, test_mode, split_X.pkl]
    ch_model_cv = ch_models_baselines.combine(ch_cv_splits.transpose())

    // [model_name, test_mode, split_X.pkl, hpam_X.yaml]
    ch_test_combis = ch_model_cv.combine(ch_hpam_combis, by: 0)

    TRAIN_AND_PREDICT_CV (
        ch_test_combis,
        params.path_data,
        params.response_transformation
    )
    // [model_name, test_mode, split_id, [hpam_0.yaml, hpam_1.yaml, ..., hpam_n.yaml], [prediction_dataset_0.pkl, prediction_dataset_1.pkl, ..., prediction_dataset_n.pkl]]
    ch_combined_hpams = TRAIN_AND_PREDICT_CV.out.groupTuple(by: [0,1,2])

    EVALUATE_FIND_MAX (
        ch_combined_hpams,
        params.optim_metric
    )

    // [split_id, test_mode, split_dataset, model_name, best_hpam_combi_X.yaml]
    ch_best_hpams_per_split = ch_cv_splits
    .map { test_mode, it -> [it, it.baseName, test_mode]}
    .transpose()
    .combine(EVALUATE_FIND_MAX.out.best_combis, by: [1, 2])

    PREDICT_FULL (
        ch_best_hpams_per_split,
        params.response_transformation,
        params.path_data
    )
    ch_vis = PREDICT_FULL.out.ch_vis

    if (params.randomization_mode != 'None') {
        ch_randomization = channel.from(randomizations)
        // randomizations only for models, not for baselines
        ch_models_rand = ch_models.combine(ch_randomization)
        RANDOMIZATION_SPLIT (
            ch_models_rand
        )
        ch_best_hpams_per_split_rand = ch_best_hpams_per_split.map {
            split_id, test_mode, path_to_split, model_name, path_to_hpams ->
            return [model_name, test_mode, split_id, path_to_split, path_to_hpams]
        }
        // [model_name, test_mode, split_id, split_dataset, best_hpam_combi_X.yaml, randomization_views]
        ch_randomization = ch_best_hpams_per_split_rand.combine(RANDOMIZATION_SPLIT.out.randomization_test_views, by: 0)
        RANDOMIZATION_TEST (
            ch_randomization,
            params.path_data,
            params.randomization_type,
            params.response_transformation
        )
        ch_vis = ch_vis.concat(RANDOMIZATION_TEST.out.ch_vis)
    }

    if (params.n_trials_robustness > 0) {
        ch_trials_robustness = Channel.from(1..params.n_trials_robustness)
        ch_trials_robustness = ch_models.combine(ch_trials_robustness)

        ch_best_hpams_per_split_rob = ch_best_hpams_per_split.map {
            split_id, test_mode, path_to_split, model_name, path_to_hpams ->
            return [model_name, test_mode, split_id, path_to_split, path_to_hpams]
        }

        // [model_name, test_mode, split_id, split_dataset, best_hpam_combi_X.yaml, robustness_iteration]
        ch_robustness = ch_best_hpams_per_split_rob.combine(ch_trials_robustness, by: 0)
        ROBUSTNESS_TEST (
            ch_robustness,
            params.path_data,
            params.randomization_type,
            params.response_transformation
        )
        ch_vis = ch_vis.concat(ROBUSTNESS_TEST.out.ch_vis)
    }

    EVALUATE_FINAL (
        ch_vis
    )

    ch_collapse = EVALUATE_FINAL.out.ch_individual_results.collect()

    COLLECT_RESULTS (
        ch_collapse
    )

    ch_test_modes_normalized = ch_test_modes.map { it + "_normalized" }
    ch_combined = ch_test_modes.combine(ch_models_baselines)
    ch_combined_mapped = ch_combined.map { it[0] + "_" + it[1] }
    ch_vio_heat = ch_test_modes.concat(ch_test_modes_normalized).concat(ch_combined_mapped)

    DRAW_VIOLIN (
        ch_vio_heat,
        COLLECT_RESULTS.out.evaluation_results
    )

    DRAW_HEATMAP (
        ch_vio_heat,
        COLLECT_RESULTS.out.evaluation_results
    )
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
