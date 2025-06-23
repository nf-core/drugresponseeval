process FIT_CURVES {
    tag "$dir_name"
    label 'high_cpu_low_mem'

    conda "${moduleDir}/env.yml"

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
