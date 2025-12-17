process POSTPROCESS_CURVECURATOR_DATA {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "python_pip_drevalpy:60b919fcfd35888b"

    input:
    val dataset_name
    path(curve_data, stageAs: "?/*")
    val measure

    output:
    path "${dataset_name}.csv", emit: path_to_dataset
    val "${measure}" + "_curvecurator", emit: measure
    path("versions.yml"),                       emit: versions

    script:
    """
    drevalpy-viability-postprocess --dataset_name ${dataset_name}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(python -c "import drevalpy; print(drevalpy.__version__)")
    END_VERSIONS
    """
}
