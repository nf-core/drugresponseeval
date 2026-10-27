process EVALUATE_FIND_MAX {
    tag "${test_mode}_${model_name}_${split_id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "matplotlib_numpy_pandas_python_pruned:4ca8e30ab27649ab"

    input:
    tuple val(model_name), val(test_mode), val(split_id), path(hpam_yamls), path(pred_datas)
    val metric

    output:
    tuple val(model_name), val(split_id), val(test_mode), path('best_hpam_combi_*.yaml'), emit: best_combis
    tuple val("${task.process}"), val('python'), eval("python --version | sed 's/Python //g'"), topic: versions, emit: versions_python
    tuple val("${task.process}"), val('drevalpy'), eval("drevalpy --version | sed 's/drevalpy //'"), topic: versions, emit: versions_drevalpy
    tuple val("${task.process}"), val('pandas'), eval("python -c \"import pandas; print(pandas.__version__)\""), topic: versions, emit: versions_pandas
    tuple val("${task.process}"), val('sklearn'), eval("python -c \"import sklearn; print(sklearn.__version__)\""), topic: versions, emit: versions_sklearn
    tuple val("${task.process}"), val('numpy'), eval("python -c \"import numpy; print(numpy.__version__)\""), topic: versions, emit: versions_numpy
    tuple val("${task.process}"), val('scipy'), eval("python -c \"import scipy; print(scipy.__version__)\""), topic: versions, emit: versions_scipy
    tuple val("${task.process}"), val('yaml'), eval("python -c \"import yaml; print(yaml.__version__)\""), topic: versions, emit: versions_yaml

    script:
    """
    drevalpy evaluate-hpams \\
        --model_name "${model_name}" \\
        --split_id $split_id \\
        --hpam_yamls $hpam_yamls \\
        --pred_datas $pred_datas \\
        --optim_metric $metric
    """

}
