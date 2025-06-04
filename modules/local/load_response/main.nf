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
    path("versions.yml"),                       emit: versions

    script:
    """
    load_response.py \\
        --dataset_name ${dataset_name} \\
        --path_data ${work_path} \\
        ${cross_study_datasets != '' ? '--cross_study_datasets ' + cross_study_datasets.replace(',', ' ') : ''} \\
        --measure ${measure}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(python -c "import drevalpy; print(drevalpy.__version__)")
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
    END_VERSIONS
    """

}
