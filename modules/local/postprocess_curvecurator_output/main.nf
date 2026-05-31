process POSTPROCESS_CURVECURATOR_DATA {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/25/258ae8d4dc806d30de817bb11421fb2316bdb3dd3305dfaa37e5ea01eb475341/data' :
        'community.wave.seqera.io/library/python_pip_drevalpy:8252ebecce29d755' }"

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
