process DRAW_CORR_COMP {
    tag "${name}"
    label 'process_single'
    publishDir "${params.outdir}/${params.run_id}/corr_comp_scatter"

    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"

    input:
    tuple val(name), path(eval_results_per_group)

    output:
    path('corr_comp_scatter*.html'), emit: corr_comp_scatter

    script:
    """
    draw_corr_comp.py \\
        --name $name \\
        --data $eval_results_per_group
    """

}
