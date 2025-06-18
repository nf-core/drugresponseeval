process TRAIN_FINAL_MODEL {
    tag { "${model_name}_${test_mode}_gpu:${task.ext.use_gpu}" }
    label 'process_high'
    label 'process_gpu'

    conda "${moduleDir}/env.yml"

    input:
    tuple val(model_name), path(response), val(test_mode), path(path_data)
    val response_transformation
    val model_checkpoint_dir
    val metric
    val no_hyperparameter_tuning


    output:
    path("**final_model/*"),                      emit: final_model
    path("versions.yml"),                       emit: versions

    script:
    """
    train_final_model.py \\
        --response $response \\
        --model_name "${model_name}" \\
        --response_transformation $response_transformation \\
        --path_data $path_data \\
        --model_checkpoint_dir $model_checkpoint_dir \\
        --metric $metric \\
        --test_mode $test_mode \\
        ${no_hyperparameter_tuning ? '' : '--hyperparameter_tuning'}


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
