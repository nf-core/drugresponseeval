
process SINGLE {
    tag "$model"
    label 'process_high'

    container 'docker.io/nicotru/drevalpy:latest'

    input:
    tuple val(model), path(split_file)
    path(dataset)
    val(no_hyperparameter_tuning)
    val(optim_metric)
    val(hpo_num_samples)

    output:
    path('*.npz'), emit: result

    when:
    task.ext.when == null || task.ext.when

    script:
    def hpo_flag = no_hyperparameter_tuning ? '--no-hpo' : '--hpo'
    """
    export XDG_CACHE_HOME=./cache/
    export XDG_CONFIG_HOME=./config/
    drevalpy single $model $dataset $split_file result.npz $hpo_flag --hpo-metric $optim_metric --hpo-num-samples $hpo_num_samples
    """

    stub:
    """
    touch result.npz
    """
}
