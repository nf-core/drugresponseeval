process HPAM_SPLIT {
    tag "$model_name"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "matplotlib_numpy_pandas_python_pruned:4ca8e30ab27649ab"

    input:
    val model_name
    val no_hyperparameter_tuning

    output:
    tuple val(model_name), path("*.yaml")    , emit: hpam_combi
    path("versions.yml"),                       emit: versions


    script:
    """
    drevalpy make-hpam-yamls \\
        --model_name "${model_name}" \\
        ${no_hyperparameter_tuning ? '' : '--hyperparameter_tuning'}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(python -c "import drevalpy; print(drevalpy.__version__)")
        yaml: \$(python -c "import yaml; print(yaml.__version__)")
    """

}
