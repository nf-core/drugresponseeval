process LOAD_RESPONSE {
    //tag "$samplesheet"
    //label 'process_single'

    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"
    input:
    val dataset_name
    val path_data
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
