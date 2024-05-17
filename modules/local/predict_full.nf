process PREDICT_FULL {
    tag "${model_name}_${split_id}"
    label 'process_single'

    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"
    input:
    tuple val(split_id), path(split_dataset), val(model_name), path(hpam_combi)
    val(response_transformation)
    val(test_mode)
    val(path_data)

    output:
    path('test_dataset_*.csv'),     emit: test_dataset

    script:
    """
    #!/usr/bin/env python
    import pickle
    import yaml
    from sklearn.preprocessing import StandardScaler, MinMaxScaler, RobustScaler

    from dreval.models import MODEL_FACTORY
    from dreval.experiment import train_and_predict

    split = pickle.load(open('${split_dataset}', 'rb'))
    train_dataset = split['train']
    validation_dataset = split['validation']
    test_dataset = split['test']

    model_class = MODEL_FACTORY['${model_name}']
    if model_class.early_stopping:
        validation_dataset = split["validation_es"]
        es_dataset = split["early_stopping"]

    train_dataset.add_rows(validation_dataset)
    train_dataset.shuffle(random_state=42)

    with open('${hpam_combi}', 'r') as f:
        best_hpam_dict = yaml.safe_load(f)
    best_hpams = best_hpam_dict['${model_name}_${split_id}']['best_hpam_combi']

    model = model_class(target='IC50')
    if '${response_transformation}' == "None":
        response_transform = None
    elif '${response_transformation}' == "standard":
        response_transform = StandardScaler()
    elif '${response_transformation}' == "minmax":
        response_transform = MinMaxScaler()
    elif '${response_transformation}' == "robust":
        response_transform = RobustScaler()
    else:
        raise ValueError("Invalid response_transform: ${response_transformation}. Choose robust, minmax or standard.")

    test_dataset = train_and_predict(
                    model=model,
                    hpams=best_hpams,
                    path_data='${path_data}',
                    train_dataset=train_dataset,
                    prediction_dataset=test_dataset,
                    early_stopping_dataset=(
                        es_dataset if model_class.early_stopping else None
                    ),
                    response_transformation=response_transform
    )

    prediction_dataset = 'test_dataset_${test_mode}_${split_id}.csv'
    test_dataset.save(prediction_dataset)
    """

}
