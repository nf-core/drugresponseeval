process POSTPROCESS_CURVECURATOR_DATA {
    label 'process_single'
    publishDir "${params.path_data}/${dataset_name}", mode: 'copy'

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
    postprocess_curvecurator_output.py --dataset_name ${dataset_name}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(python -c "import drevalpy; print(drevalpy.__version__)")
    END_VERSIONS
    """
}
