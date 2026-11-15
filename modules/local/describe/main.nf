
process DESCRIBE {
    tag "describe"
    label 'process_single'

    input:
    val(models)

    output:
    path('models.tsv'), emit: tsv
    tuple val("${task.process}"), val('drevalpy'), eval("drevalpy --version | sed 's/^drevalpy //'"), topic: versions, emit: versions_drevalpy

    when:
    task.ext.when == null || task.ext.when

    script:
    def model_args = models.collect { model -> "'${model}'" }.join(' ')
    """
    export XDG_CACHE_HOME=./cache/
    export XDG_CONFIG_HOME=./config/
    drevalpy describe ${model_args} --tsv models.tsv
    """

    stub:
    // Same as the script: describe is offline and fast, and -stub-run then routes models like a real run.
    def model_args = models.collect { model -> "'${model}'" }.join(' ')
    """
    export XDG_CACHE_HOME=./cache/
    export XDG_CONFIG_HOME=./config/
    drevalpy describe ${model_args} --tsv models.tsv
    """
}
