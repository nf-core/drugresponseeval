process LOAD_RESPONSE {
    tag "${response.baseName}"
    label 'process_single'



    input:
    tuple val(measure), path(response)
    val cross_study_dataset

    output:
    path 'response_dataset.pkl',    emit: response_dataset, optional: true
    path 'cross_study_*.pkl',       emit: cross_study_datasets, optional: true
    path("versions.yml"),                       emit: versions

    script:
    """
    load_response.py \\
        --response_dataset ${response} \\
        --measure ${measure} \\
        ${cross_study_dataset ? '--cross_study_dataset' : ''}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(python -c "import drevalpy; print(drevalpy.__version__)")
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
    END_VERSIONS
    """

}
