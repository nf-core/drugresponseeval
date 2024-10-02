process CONSOLIDATE_RESULTS {
    tag "Consolidate"
    label 'process_single'
    publishDir "${params.outdir}/${params.run_id}/${test_mode}", mode: 'copy'

    input:
    tuple val(test_mode), val(model_names), val(pred_files)
    val(rand_modes)

    output:
    tuple val(test_mode), val(model_names), val(pred_files)

    script:
    """
    consolidate_results.py \\
        --test_mode ${test_mode} \\
        --model_names "${model_names}" \\
        --pred_files "${pred_files}" \\
        --n_cv_splits ${params.n_cv_splits} \\
        ${params.cross_study_datasets != '' ? '--cross_study_datasets ' + params
        .cross_study_datasets.replace(',', ' ') : ''} \\
        --randomizations ${rand_modes}\\
        --n_trials_robustness ${params.n_trials_robustness}

    """
}
