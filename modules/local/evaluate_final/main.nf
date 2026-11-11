process EVALUATE_FINAL {
    tag "${test_mode}_${model_name}_${pred_file}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "matplotlib_numpy_pandas_python_pruned:4ca8e30ab27649ab"

    input:
    tuple val(test_mode), val(model_name), path(pred_file)

    output:
    path('*.csv'), emit: ch_individual_results, optional: true
    tuple val("${task.process}"), val('python'), eval("python --version | sed 's/Python //g'"), topic: versions, emit: versions_python
    tuple val("${task.process}"), val('drevalpy'), eval("drevalpy --version | sed 's/drevalpy //'"), topic: versions, emit: versions_drevalpy
    tuple val("${task.process}"), val('pandas'), eval("python -c \"import pandas; print(pandas.__version__)\""), topic: versions, emit: versions_pandas
    tuple val("${task.process}"), val('sklearn'), eval("python -c \"import sklearn; print(sklearn.__version__)\""), topic: versions, emit: versions_sklearn
    tuple val("${task.process}"), val('numpy'), eval("python -c \"import numpy; print(numpy.__version__)\""), topic: versions, emit: versions_numpy
    tuple val("${task.process}"), val('scipy'), eval("python -c \"import scipy; print(scipy.__version__)\""), topic: versions, emit: versions_scipy


    script:
    """
    drevalpy evaluate-test \\
        --test_mode $test_mode \\
        --model_name "${model_name}" \\
        --pred_file $pred_file
    """

}
