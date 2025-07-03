process TRAIN_AND_PREDICT_CV {
    tag { "${model_name}_${test_mode}_gpu:${task.ext.use_gpu}" }
    label 'process_high'
    label 'process_gpu'



    input:
    tuple val(model_name), val(test_mode), path(cv_data), path(hyperparameters), path(path_data)
    val response_transformation
    val model_checkpoint_dir


    output:
    tuple val(model_name), val(test_mode), val(cv_data.baseName), path(hyperparameters), path("prediction_dataset_*.pkl"), emit: pred_data
    path("versions.yml"),                       emit: versions

    script:
    """
    train_and_predict_cv.py \\
        --model_name "${model_name}" \\
        --path_data $path_data \\
        --test_mode $test_mode \\
        --hyperparameters $hyperparameters \\
        --cv_data $cv_data \\
        --response_transformation $response_transformation \\
        --model_checkpoint_dir $model_checkpoint_dir

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
