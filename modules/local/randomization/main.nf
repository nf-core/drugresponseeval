
process RANDOMIZATION {
    tag "$model"
    label 'process_medium'

    container 'docker.io/nicotru/drevalpy:latest'

    input:
    val(model)
    path(dataset)
    val(modes)
    val(randomization_type)
    val(random_state)

    output:
    path('randomized/*.h5mu'), emit: datasets

    when:
    task.ext.when == null || task.ext.when

    script:
    def mode_flags = modes.collect { "--mode $it" }.join(' ')
    """
    mkdir -p randomized
    drevalpy experiments randomization $model $dataset randomized $mode_flags --randomization-type $randomization_type --random-state $random_state
    """
}
