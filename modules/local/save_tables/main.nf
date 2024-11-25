process SAVE_TABLES {
    tag "${lpo_lco_ldo}_${eval_results}"
    label 'process_single'
    publishDir "${params.outdir}/${params.run_id}/html_tables", mode: 'copy'

    input:
    tuple val(lpo_lco_ldo), path(eval_results)

    output:
    path('table*.html'), emit: html_table

    script:
    """
    save_tables.py \\
        --path_eval_results ${eval_results} \\
        --lpo_lco_ldo ${lpo_lco_ldo}
    """

}
