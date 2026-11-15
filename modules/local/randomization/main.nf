
process RANDOMIZATION {
    tag "$model"
    label 'process_medium'

    input:
    val(model)
    path(dataset)
    val(modes)
    val(randomization_type)
    val(seed)

    output:
    path('randomized/*.h5mu'), emit: datasets
    tuple val("${task.process}"), val('drevalpy'), eval("drevalpy --version | sed 's/^drevalpy //'"), topic: versions, emit: versions_drevalpy

    when:
    task.ext.when == null || task.ext.when

    script:
    def mode_flags = modes.collect { "--mode ${it.toLowerCase()}" }.join(' ')
    """
    export XDG_CACHE_HOME=./cache/
    export XDG_CONFIG_HOME=./config/
    mkdir -p randomized
    drevalpy experiments randomization '${model}' ${dataset} randomized ${mode_flags} --randomization-type ${randomization_type} --seed ${seed}
    """
}
