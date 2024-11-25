process DRAW_HEATMAP {
    tag "${name}"
    label 'process_single'
    publishDir "${params.outdir}/${params.run_id}/heatmaps", mode: 'copy'

    input:
    val(name)
    path(eval_results)

    output:
    path('heatmap*.html'), emit: heatmap

    script:
    """
    draw_violin_and_heatmap.py \\
        --plot heatmap \\
        --name $name \\
        --data $eval_results
    """

}
