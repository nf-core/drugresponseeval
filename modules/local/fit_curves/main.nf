process FIT_CURVES {
    //tag "$samplesheet"
    label 'high_cpu_low_mem'
    publishDir "${path_data}", mode: 'copy'


    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"

    input:
    val dataset_name
    path toml
    path curvecurator_input

    output:
    path "${dataset_name}/curves.txt", emit: path_to_curvecurator_out
    path "${dataset_name}/norm.txt"
    path "${dataset_name}/mad.txt"
    path "${dataset_name}/dashboard.html"

    script:
    """
    CurveCurator ${toml} --mad
    """
}
