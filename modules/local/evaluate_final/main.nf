process EVALUATE_FINAL {
    tag "${test_mode}_${model_name}_${pred_file}"
    label 'process_single'

    input:
    tuple val(test_mode), val(model_name), path(pred_file)

    output:
    path('*.csv'), emit: ch_individual_results, optional: true
    path("versions.yml"),                       emit: versions

    script:
    """
    evaluate_final.py \\
        --test_mode $test_mode \\
        --model_name "${model_name}" \\
        --pred_file $pred_file

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(python -c "import drevalpy; print(drevalpy.__version__)")
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
        sklearn: \$(python -c "import sklearn; print(sklearn.__version__)")
        numpy: \$(python -c "import numpy; print(numpy.__version__)")
        scipy: \$(python -c "import scipy; print(scipy.__version__)")
    END_VERSIONS
    """

}
