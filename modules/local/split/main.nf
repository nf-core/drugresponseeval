
process SPLIT {
    tag "$dataset:$mode:$n_splits"
    label 'process_single'

    input:
    path(dataset)
    val(mode)
    val(n_splits)
    val(measure)

    output:
    path('splits/*.npz'), emit: folds
    tuple val("${task.process}"), val('drevalpy'), eval("drevalpy --version | sed 's/^drevalpy //'"), topic: versions, emit: versions_drevalpy

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    export XDG_CACHE_HOME=./cache/
    export XDG_CONFIG_HOME=./config/
    mkdir -p splits
    drevalpy data split $dataset splits --mode $mode --n-splits $n_splits --measure $measure
    """

    stub:
    """
    mkdir -p splits
    for i in {1..$n_splits}; do
        touch splits/fold_\$i.npz
    done
    """
}
