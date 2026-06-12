process LOAD_RESPONSE {
    tag "${response.baseName}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "matplotlib_numpy_pandas_python_pruned:4ca8e30ab27649ab"

    input:
    tuple val(measure), path(response)
    val cross_study_dataset

    output:
    path 'response_dataset.pkl',    emit: response_dataset, optional: true
    path 'cross_study_*.pkl',       emit: cross_study_datasets, optional: true
    path("versions.yml"),                       emit: versions

    script:
    """
    drevalpy load-response \\
        --response_dataset ${response} \\
        --measure ${measure} \\
        ${cross_study_dataset ? '--cross_study_dataset' : ''}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(drevalpy --version | sed 's/drevalpy //g')
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
    END_VERSIONS
    """

}
