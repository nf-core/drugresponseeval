
process ROBUSTNESS {
    tag "robustness"
    label 'process_single'

    input:
    path(splits_dir)
    val(n_permutations)

    output:
    path('robustness_splits/*.npz'), emit: splits

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    export XDG_CACHE_HOME=./cache/
    export XDG_CONFIG_HOME=./config/
    mkdir -p robustness_splits
    drevalpy experiments robustness $splits_dir robustness_splits --n-permutations $n_permutations
    """
}
