process VISUALIZE_RESULTS {
    label 'process_medium'
    publishDir "${params.outdir}/${params.run_id}", mode: 'copy'

    input:
    tuple path(eval_results), path(eval_results_per_drug), path(eval_results_per_cl), path(true_vs_predicted)
    val(path_data)

    output:
    path('report/*'), emit: html_out

    script:
    """
    visualize_results.py \\
        --test_modes ${params.test_mode.replace(',', ' ')} \\
        --eval_results $eval_results \\
        --eval_results_per_drug $eval_results_per_drug \\
        --eval_results_per_cl $eval_results_per_cl \\
        --true_vs_predicted $true_vs_predicted \\
        --path_data $path_data
    """

}
