process DRAW_VIOLIN {
    tag "${name}"
    label 'process_single'
    publishDir "${params.outdir}/${params.run_id}/violin_plots", mode: 'copy'

    input:
    val(name)
    path(eval_results)

    output:
    path('violin*.html'), emit: violin_plot

    script:
    """
    draw_violin_and_heatmap.py \\
        --plot violinplot \\
        --name $name \\
        --data $eval_results
    """

}
