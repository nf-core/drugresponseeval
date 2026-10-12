process FIT_CURVES {
    tag "$dir_name"
    label 'high_cpu_low_mem'

    conda "${moduleDir}/environment.yml"
    container "python_pip_curve-curator:8f275bea1867edfd"

    input:
    val dataset_name
    tuple val(dir_name), path(toml), path(curvecurator_input)

    output:
    path("curves.tsv"),                         emit: path_to_curvecurator_out
    tuple path("mad.txt"), path("dashboard.html"), path("curveCurator.log") // other output
    tuple val("${task.process}"), val('curve_curator'), eval("python -c \"import curve_curator; print(curve_curator.__version__)\""), topic: versions, emit: versions_curve_curator

    script:
    """
    CurveCurator ${toml} --mad
    """
}
