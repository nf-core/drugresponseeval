process LOAD_RESPONSE {
    tag "${response.baseName}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/88/88d06bd843a342074e5def5c95e7d993cfe4a7f0acb7c41eb6c00e78d9ce8654/data'
        : 'python_pip_drevalpy:a2b7a0d499377204'}"

    input:
    tuple val(measure), path(response)
    val cross_study_dataset

    output:
    path 'response_dataset.pkl',    emit: response_dataset, optional: true
    path 'cross_study_*.pkl',       emit: cross_study_datasets, optional: true
    path("versions.yml"),                       emit: versions

    script:
    """
    drevalpy-load-response \\
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
