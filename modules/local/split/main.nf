
process SPLIT {
    tag "$dataset"
    label 'process_single'

    container 'docker.io/nicotru/drevalpy:latest'

    input:
    path(dataset)
    val(mode)
    val(n_splits)

    output:
    path('splits/*.npz'), emit: folds

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    mkdir -p splits
    drevalpy data split $dataset splits --mode $mode --n-splits $n_splits
    """

    stub:
    """
    mkdir -p splits
    for i in {1..$n_splits}; do
        touch splits/fold_\$i.npz
    done
    """
}
