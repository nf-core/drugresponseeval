process HPAM_SPLIT {
    tag "$model_name"
    label 'process_single'

    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"
    input:
    val model_name

    output:
    tuple val(model_name), path("*.yaml")    , emit: hpam_combi


    script:
    """
    hpam_split.py \\
        --model_name $model_name
    """

}
