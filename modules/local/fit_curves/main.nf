process FIT_CURVES {
    tag "$dir_name"
    label 'high_cpu_low_mem'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/25/258ae8d4dc806d30de817bb11421fb2316bdb3dd3305dfaa37e5ea01eb475341/data' :
        'community.wave.seqera.io/library/python_pip_drevalpy:8252ebecce29d755' }"

    input:
    val dataset_name
    tuple val(dir_name), path(toml), path(curvecurator_input)

    output:
    path("curves.tsv"),                         emit: path_to_curvecurator_out
    tuple path("mad.txt"), path("dashboard.html"), path("curveCurator.log") // other output
    path("versions.yml"),                       emit: versions

    script:
    """
    CurveCurator ${toml} --mad

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        curve_curator: \$(python -c "import curve_curator; print(curve_curator.__version__)")
    END_VERSIONS
    """
}
