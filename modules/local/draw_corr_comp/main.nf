process DRAW_CORR_COMP {
    tag "${name}"
    label 'process_single'
    publishDir "${params.outdir}/${params.run_id}/corr_comp_scatter", mode: 'copy'

    input:
    tuple val(name), path(eval_results_per_group)

    output:
    path('corr_comp_scatter*.html'), emit: corr_comp_scatter, optional: true

    script:
    """
    draw_corr_comp.py \\
        --name $name \\
        --data $eval_results_per_group
    """

}
