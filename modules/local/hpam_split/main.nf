process HPAM_SPLIT {
    tag "$model_name"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/90/908156ca5b3770a1797cd6f564cea34935ab7b09b39643436494f3bdf6331266/data' :
        'community.wave.seqera.io/library/matplotlib_numpy_pandas_python_pruned:0868f8788117e11b' }"

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
