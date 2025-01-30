process FIT_CURVES {
    tag "$dir_name"
    label 'high_cpu_low_mem'

    input:
    val dataset_name
    tuple val(dir_name), path(toml), path(curvecurator_input)

    output:
    path("curves.tsv"), emit: path_to_curvecurator_out
    tuple path("mad.txt"), path("dashboard.html"), path("curveCurator.log") // other output

    script:
    """
    CurveCurator ${toml} --mad
    """
}
