process LOAD_RESPONSE {
    tag "${response.baseName}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/25/258ae8d4dc806d30de817bb11421fb2316bdb3dd3305dfaa37e5ea01eb475341/data' :
        'community.wave.seqera.io/library/python_pip_drevalpy:8252ebecce29d755' }"

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
