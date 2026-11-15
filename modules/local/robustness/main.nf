
process ROBUSTNESS {
    tag "robustness"
    label 'process_single'

    input:
    path(splits_dir)
    val(n_repeats)

    output:
    path('robustness_splits/*.npz'), emit: splits
    tuple val("${task.process}"), val('drevalpy'), eval("drevalpy --version | sed 's/^drevalpy //'"), topic: versions, emit: versions_drevalpy

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    export XDG_CACHE_HOME=./cache/
    export XDG_CONFIG_HOME=./config/
    mkdir -p robustness_splits
    drevalpy experiments robustness $splits_dir robustness_splits --n-repeats $n_repeats
    """
}
