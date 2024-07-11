process DRAW_VIOLIN {
    tag "${name}"
    label 'process_single'
    publishDir "${params.outdir}/${params.run_id}/violin_plots"

    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"

    input:
    val(name)
    path(eval_results)

    output:
    path('violinplot*.html'), emit: violin_plot

    script:
    """
    draw_violin_and_heatmap.py \\
        --plot violinplot \\
        --name $name \\
        --data $eval_results
    """

}
