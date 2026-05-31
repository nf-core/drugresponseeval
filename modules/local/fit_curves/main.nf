process FIT_CURVES {
    tag "$dir_name"
    label 'high_cpu_low_mem'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/90/908156ca5b3770a1797cd6f564cea34935ab7b09b39643436494f3bdf6331266/data' :
        'community.wave.seqera.io/library/matplotlib_numpy_pandas_python_pruned:0868f8788117e11b' }"

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
