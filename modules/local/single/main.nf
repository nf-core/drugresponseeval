
process SINGLE {
    tag "$model-${split_file.baseName}"
    label 'process_high'
    label 'process_gpu'

    input:
    tuple val(model), path(split_file)
    path(dataset)
    val(no_hyperparameter_tuning)
    val(optim_metric)
    val(hpo_trials)
    val(response_transformation)

    output:
    path('*.npz'), emit: result
    tuple val("${task.process}"), val('drevalpy'), eval("drevalpy --version | sed 's/^drevalpy //'"), topic: versions, emit: versions_drevalpy

    when:
    task.ext.when == null || task.ext.when

    script:
    def hpo_flag = no_hyperparameter_tuning ? '--no-hpo' : '--hpo'
    """
    export XDG_CACHE_HOME=./cache/
    export XDG_CONFIG_HOME=./config/
    drevalpy single '${model}' ${dataset} ${split_file} '${model}-${split_file.baseName}.npz' \\
        ${hpo_flag} \\
        --hpo-metric '${optim_metric}' \\
        --hpo-trials ${hpo_trials} \\
        --response-transformation ${response_transformation} \\
        --n-jobs ${task.cpus}
    """

    stub:
    """
    touch '${model}-${split_file.baseName}.npz'
    """
}
