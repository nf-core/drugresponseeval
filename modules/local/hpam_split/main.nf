process HPAM_SPLIT {
    tag "$model_name"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/88/88d06bd843a342074e5def5c95e7d993cfe4a7f0acb7c41eb6c00e78d9ce8654/data'
        : 'python_pip_drevalpy:a2b7a0d499377204'}"

    input:
    val model_name
    val no_hyperparameter_tuning

    output:
    tuple val(model_name), path("*.yaml")    , emit: hpam_combi
    path("versions.yml"),                       emit: versions


    script:
    """
    drevalpy-make-hpam-yamls \\
        --model_name "${model_name}" \\
        ${no_hyperparameter_tuning ? '' : '--hyperparameter_tuning'}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(python -c "import drevalpy; print(drevalpy.__version__)")
        yaml: \$(python -c "import yaml; print(yaml.__version__)")
    """

}
