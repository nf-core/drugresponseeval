process WRITE_HTML {
    tag "${test_mode}"
    label 'process_single'
    publishDir "${params.outdir}/${params.run_id}"

    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"

    input:
    val(run_id)
    tuple val(test_mode), path(files)

    output:
    path('*.html'), emit: html_out

    script:
    """
    write_html.py \\
        --run_id $run_id \\
        --test_mode $test_mode \\
        --files $files
    """

}
