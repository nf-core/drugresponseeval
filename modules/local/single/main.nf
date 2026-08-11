
process SINGLE {
    tag "$model/$split_file.baseName"
    label 'process_high'

    container 'docker.io/nicotru/drevalpy:latest'

    input:
    val(model)
    path(dataset)
    path(split_file)
    val(split_mode)
    val(hpo)
    val(hpo_metric)
    val(hpo_num_samples)
    val(hpo_random_state)

    output:
    path('*.npz'), emit: result

    when:
    task.ext.when == null || task.ext.when

    script:
    def hpo_flag = hpo ? '--hpo' : '--no-hpo'
    """
    drevalpy single $model $dataset $split_file result.npz $hpo_flag --hpo-metric $hpo_metric --hpo-num-samples $hpo_num_samples --hpo-random-state $hpo_random_state --split-mode $split_mode
    """
}
