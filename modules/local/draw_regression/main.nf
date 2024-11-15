process DRAW_REGRESSION {
    tag "${name}_${model}"
    label 'process_single'
    publishDir "${params.outdir}/${params.run_id}/regression_plots"

    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"

    input:
    tuple val(name), val(model), path(true_vs_pred)

    output:
    path('regression_lines*.html'), emit: regression_lines

    script:
    """
    draw_regression.py \\
    --path_t_vs_p ${true_vs_pred} \\
    --name ${name} \\
    --model ${model}
    """

}
