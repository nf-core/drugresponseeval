process MAKE_MODEL_CHANNEL {
    tag "Make model channel"
    label 'process_single'

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
