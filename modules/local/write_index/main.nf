process WRITE_INDEX {
    //tag "index"
    label 'process_single'

    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"

    input:
    val(run_id)
    val(test_modes)
    val(nr_html_files)

    output:
    path('*.html'), emit: html_out
    path('*.png'), emit: graphic_elements

    script:
    """
    write_index.py \\
        --run_id ${run_id} \\
        --test_modes ${test_modes}
    """

}
