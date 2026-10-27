process LOAD_RESPONSE {
    tag "${response.baseName}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "matplotlib_numpy_pandas_python_pruned:4ca8e30ab27649ab"

    input:
    tuple val(measure), path(response)
    val cross_study_dataset
    val clean_min_responders
    val clean_min_responder_frac

    output:
    path 'response_dataset.pkl',    emit: response_dataset, optional: true
    path 'cross_study_*.pkl',       emit: cross_study_datasets, optional: true
    tuple val("${task.process}"), val('python'), eval("python --version | sed 's/Python //g'"), topic: versions, emit: versions_python
    tuple val("${task.process}"), val('drevalpy'), eval("drevalpy --version | sed 's/drevalpy //'"), topic: versions, emit: versions_drevalpy
    tuple val("${task.process}"), val('pandas'), eval("python -c \"import pandas; print(pandas.__version__)\""), topic: versions, emit: versions_pandas

    script:
    """
    drevalpy load-response \\
        --response_dataset ${response} \\
        --measure ${measure} \\
        ${cross_study_dataset ? '--cross_study_dataset' : ''} \\
        ${clean_min_responders ? "--clean_min_responders ${clean_min_responders}" : ''} \\
        ${clean_min_responder_frac ? "--clean_min_responder_frac ${clean_min_responder_frac}" : ''}
    """

}
