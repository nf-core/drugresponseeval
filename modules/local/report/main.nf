
process REPORT {
    tag "report"
    label 'process_medium'

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
    # Unbuffered stdout so the last progress line survives an OOM SIGKILL; a buffered run
    # of this process died with exit 137 and an empty log, hiding which plot failed.
    export PYTHONUNBUFFERED=1
    drevalpy report $experiment_dir --output-dir report/ --title "$title" --reference-model "$reference_model" --dataset "$dataset_path"
    """

    stub:
    """
    mkdir -p report
    touch report/report.html
    """
}
