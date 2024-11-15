process SAVE_TABLES {
    tag "${lpo_lco_ldo}_${eval_results}"
    label 'process_single'
    publishDir "${params.outdir}/${params.run_id}/html_tables"

    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"

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
