process LOAD_RESPONSE {
    tag "${response.baseName}"
    label 'process_single'

    input:
    tuple val(measure), path(response)
    val no_refitting
    val cross_study_dataset

    output:
    path 'response_dataset.pkl',    emit: response_dataset, optional: true
    path 'cross_study_*.pkl',       emit: cross_study_datasets, optional: true

    script:
    """
    load_response.py \\
        --response_dataset ${response} \\
        --measure ${measure} \\
        ${no_refitting ? '--no_refitting' : ''} \\
        ${cross_study_dataset ? '--cross_study_dataset' : ''}
    """

}
