process LOAD_RESPONSE {
    tag "${dataset_name} (cross: ${cross_study_datasets})"
    label 'process_single'

    input:
    val dataset_name
    path work_path
    val cross_study_datasets
    val measure

    output:
    path 'response_dataset.pkl',    emit: response_dataset
    path 'cross_study_*.pkl',       emit: cross_study_datasets, optional: true

    script:
    """
    load_response.py \\
        --dataset_name ${dataset_name} \\
        --path_data ${work_path} \\
        ${cross_study_datasets != '' ? '--cross_study_datasets ' + cross_study_datasets.replace(',', ' ') : ''} \\
        --measure ${measure}
    """

}
