process HPAM_SPLIT {
    tag "$model_name"
    label 'process_single'

    conda "${moduleDir}/env.yml"

    input:
    val model_name

    output:
    tuple val(model_name), path("*.yaml")    , emit: hpam_combi
    path("versions.yml"),                       emit: versions


    script:
    """
    hpam_split.py \\
        --model_name "${model_name}"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(python -c "import drevalpy; print(drevalpy.__version__)")
        yaml: \$(python -c "import yaml; print(yaml.__version__)")
    """

}
