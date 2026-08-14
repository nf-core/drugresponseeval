
process SINGLE {
    tag "$model-${split_file.baseName}"
    label 'process_high'

    input:
    tuple val(model), path(split_file)
    path(dataset)
    val(no_hyperparameter_tuning)
    val(optim_metric)
    val(hpo_num_samples)
    val(response_transformation)

    output:
    path('*.npz'), emit: result

    when:
    task.ext.when == null || task.ext.when

    script:
    def hpo_flag = no_hyperparameter_tuning ? '--no-hpo' : '--hpo'
    """
    export XDG_CACHE_HOME=./cache/
    export XDG_CONFIG_HOME=./config/
    drevalpy single $model $dataset $split_file ${model}-${split_file.baseName}.npz $hpo_flag --hpo-metric $optim_metric --hpo-num-samples $hpo_num_samples --response-transformation $response_transformation
    """

    stub:
    """
    touch ${model}-${split_file.baseName}.npz
    """
}
