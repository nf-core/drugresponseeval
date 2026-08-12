
process REPORT {
    tag "report"
    label 'process_single'

    container 'docker.io/nicotru/drevalpy:latest'

    input:
    path(experiment_dir)
    val(title)
    val(reference_model)
    path(dataset_path)

    output:
    path("report/**"), emit: report

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    export XDG_CACHE_HOME=./cache/
    export XDG_CONFIG_HOME=./config/
    drevalpy report $experiment_dir --output-dir report/ --title "$title" --reference-model "$reference_model" --dataset "$dataset_path"
    """

    stub:
    """
    mkdir -p report
    touch report/report.html
    """
}
