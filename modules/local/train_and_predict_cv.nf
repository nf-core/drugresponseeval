process TRAIN_AND_PREDICT_CV {
    label 'process_single'

    input:
    val model_name
    val test_mode
    path hyperparameters
    path cv_data
    val response_transformation

    output:
    path "prediction_dataset.pkl", emit: pred_data

    script:
    """
    train_and_predict_cv.py \\
        --model_name $model_name \\
        --test_mode $test_mode \\
        --hyperparameters $hyperparameters \\
        --cv_data $cv_data \\
        --response_transformation $response_transformation
    """
}
