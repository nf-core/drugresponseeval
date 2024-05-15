

process TRAIN_AND_PREDICT {
    input:
    val model_name
    path hyperparameters
    path train_data
    path prediction_data
    path early_stopping_data
    val response_transformation
    path cl_features
    path drug_features

    output:
    path "*.pkl"    , emit: pred_data

    script:
    """
    train_and_predict.py \\
        --model_name $model_name \\
        --hyperparameters $hyperparameters \\
        --train_data $train_data \\
        --prediction_data $prediction_data \\
        --early_stopping_data $early_stopping_data \\
        --response_transformation $response_transformation \\
        --cl_features $cl_features \\
        --drug_features $drug_features
    """

}
