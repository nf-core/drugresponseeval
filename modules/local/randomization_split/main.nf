process RANDOMIZATION_SPLIT {
    tag "${model_name}_${randomization_mode}"
    label 'process_single'

    input:
    tuple val(model_name), val(randomization_mode)

    output:
    tuple val(model_name), path('randomization_test_view*.yaml'),     emit: randomization_test_views

    script:
    """
    randomization_split.py --model_name "${model_name}" --randomization_mode ${randomization_mode}
    """

}
