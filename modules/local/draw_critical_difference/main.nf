process DRAW_CRITICAL_DIFFERENCE {
    tag "${lpo_lco_ldo}"
    label 'process_single'
    publishDir "${params.outdir}/${params.run_id}/critical_difference_plots"

    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"

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
