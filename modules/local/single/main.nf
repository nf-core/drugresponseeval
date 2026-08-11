
process SINGLE {
    label 'process_high'

    container 'docker.io/nicotru/drevalpy:latest'

    input:
    tuple val(model), path(split_file)
    path(dataset)

    output:
    path('*.npz'), emit: result

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    export XDG_CACHE_HOME=./cache/
    export XDG_CONFIG_HOME=./config/
    drevalpy single $model $dataset $split_file result.npz
    """

    stub:
    """
    touch result.npz
    """
}
