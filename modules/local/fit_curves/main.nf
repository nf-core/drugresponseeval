process FIT_CURVES {
    tag "$dir_name"
    label 'high_cpu_low_mem'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/88/88d06bd843a342074e5def5c95e7d993cfe4a7f0acb7c41eb6c00e78d9ce8654/data'
        : 'python_pip_drevalpy:a2b7a0d499377204'}"

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
