process MAKE_MODEL_CHANNEL {
    tag "Make model channel"
    //label 'process_single'

    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"
    input:
    tuple val(models), path(response_data)
    val(name)

    output:
    path '{models,baselines}*.txt',    emit: all_models

    script:
    """
    make_model_channel.py \\
        --models "${models}" \\
        --data ${response_data} \\
        --file_name ${name}
    """

}
