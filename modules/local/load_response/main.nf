process LOAD_RESPONSE {
    tag "${dataset_name} (cross: ${cross_study_datasets})"
    label 'process_single'
    publishDir "${path_data}", mode: 'copy'

    input:
    val dataset_name
    path path_data
    val cross_study_datasets

    output:
    path 'response_dataset.pkl',    emit: response_dataset
    path 'cross_study_*.pkl',       emit: cross_study_datasets, optional: true
    script:
    """
    load_response.py \\
        --dataset_name ${dataset_name} \\
        --path_data ${path_data} \\
        ${cross_study_datasets != '' ? '--cross_study_datasets ' + cross_study_datasets.replace(',', ' ') : ''}
    """

}
