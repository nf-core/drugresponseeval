

process TRAIN_AND_PREDICT {
    input:
    val model_name
    val hyperparameters
    path train_data
    path prediction_data
    path early_stopping_data
    val response_transformation
    path cl_features
    path drug_features

}
