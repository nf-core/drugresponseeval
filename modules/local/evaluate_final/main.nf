process EVALUATE_FINAL {
    tag "${test_mode}_${model_name}_${pred_file}"
    label 'process_single'

    input:
    tuple val(test_mode), val(model_name), path(pred_file)

    output:
    path('*.csv'), emit: ch_individual_results, optional: true

    script:
    """
    evaluate_final.py \\
        --test_mode $test_mode \\
        --model_name "${model_name}" \\
        --pred_file $pred_file
    """

}
