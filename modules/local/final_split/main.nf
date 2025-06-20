process FINAL_SPLIT {
    tag { "${model_name}_${test_mode}_gpu:${task.ext.use_gpu}" }
    label 'process_single'

    conda "${moduleDir}/env.yml"

    input:
    tuple val(model_name), path(response), val(test_mode), path(path_data)


    output:
    tuple val(model_name), path("training_dataset.pkl"), path("validation_dataset.pkl"), path("early_stopping_dataset.pkl"),    emit: final_datasets
    path("versions.yml"),                                                                                                       emit: versions

    script:
    """
    final_split.py \\
        --response $response \\
        --model_name "${model_name}" \\
        --path_data $path_data \\
        --test_mode $test_mode


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(python -c "import drevalpy; print(drevalpy.__version__)")
        sklearn: \$(python -c "import sklearn; print(sklearn.__version__)")
        numpy: \$(python -c "import numpy; print(numpy.__version__)")
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
        pytorch_lightning: \$(python -c "import pytorch_lightning; print(pytorch_lightning.__version__)")
        torch: \$(python -c "import torch; print(torch.__version__)" | sed 's/+.*//')
        platform: \$(python -c "import platform; print(platform.__version__)")
    END_VERSIONS
    """
}
