
process SPLIT {
    tag "$dataset"
    label 'process_single'

    container 'docker.io/nicotru/drevalpy:latest'

    input:
    path(dataset)
    val(mode)
    val(n_splits)
    val(validation_ratio)
    val(random_state)

    output:
    path('splits/*.npz'), emit: folds

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    mkdir -p splits
    drevalpy data split $dataset splits --mode $mode --n-splits $n_splits --validation-ratio $validation_ratio --random-state $random_state
    """
}
