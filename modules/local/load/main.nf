
process LOAD {
    tag "$dataset"
    label 'process_single'

    input:
    val(dataset)

    output:
    path('*.h5mu'), emit: data

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    export XDG_CACHE_HOME=./cache/
    export XDG_CONFIG_HOME=./config/
    drevalpy data load $dataset ${dataset}.h5mu
    """

    stub:
    """
    touch ${dataset}.h5mu
    """
}
