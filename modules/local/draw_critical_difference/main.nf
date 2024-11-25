process DRAW_CRITICAL_DIFFERENCE {
    tag "${lpo_lco_ldo}"
    label 'process_single'
    publishDir "${params.outdir}/${params.run_id}/critical_difference_plots", mode: 'copy'

    input:
    tuple val(lpo_lco_ldo), path(eval_results)

    output:
    path('critical_difference*.svg'), emit: critical_difference, optional: true

    script:
    """
    draw_cd.py \\
        --name $lpo_lco_ldo \\
        --data $eval_results
    """

}
