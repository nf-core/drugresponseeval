process TRAIN_AND_PREDICT_CV {
    tag { "${model_name}_${test_mode}_gpu:${task.ext.use_gpu}" }
    label 'process_high'
    label 'process_gpu'

    input:
    tuple val(model_name), val(test_mode), path(cv_data), path(hyperparameters)
    path path_data
    val response_transformation
    val model_checkpoint_dir


    output:
    tuple val(model_name), val(test_mode), val(cv_data.baseName), path(hyperparameters), path("prediction_dataset_*.pkl"), emit: pred_data

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
    """
}
