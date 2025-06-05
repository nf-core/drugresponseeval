process MAKE_MODEL_CHANNEL {
    tag "Make model channel"
    label 'process_single'

    input:
    tuple val(models), path(response_data)
    val(name)

    output:
    path '{models,baselines}*.txt',    emit: all_models
    path("versions.yml"),                       emit: versions

    script:
    """
    make_model_channel.py \\
        --models "${models}" \\
        --data ${response_data} \\
        --file_name ${name}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(python -c "import drevalpy; print(drevalpy.__version__)")
        sklearn: \$(python -c "import sklearn; print(sklearn.__version__)")
        numpy: \$(python -c "import numpy; print(numpy.__version__)")
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
        pytorch_lightning: \$(python -c "import pytorch_lightning; print(pytorch_lightning.__version__)")
        torch: \$(python -c "import torch; print(torch.__version__)")
        platform: \$(python -c "import platform; print(platform.__version__)")
    END_VERSIONS
    """

}
