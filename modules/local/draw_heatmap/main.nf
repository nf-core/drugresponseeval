process DRAW_HEATMAP {
    tag "${name}"
    label 'process_single'
    publishDir "${params.outdir}/${params.run_id}/heatmaps", mode: 'copy'

    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"

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
