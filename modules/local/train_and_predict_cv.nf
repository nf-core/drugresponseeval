process TRAIN_AND_PREDICT_CV {
    label 'process_single'

    input:
    tuple val(model_name), path(cv_data), path(hyperparameters)
    val path_data
    val test_mode
    val response_transformation

    output:
    path "prediction_dataset.pkl", emit: pred_data

    script:
    """
    train_and_predict_cv.py \\
        --model_name $model_name \\
        --path_data $path_data \\
        --test_mode $test_mode \\
        --hyperparameters $hyperparameters \\
        --cv_data $cv_data \\
        --response_transformation $response_transformation
    """
}
