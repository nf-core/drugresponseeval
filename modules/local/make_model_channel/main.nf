process MAKE_MODEL_CHANNEL {
    tag "Make model channel"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "matplotlib_numpy_pandas_python_pruned:4ca8e30ab27649ab"

    input:
    tuple val(models), path(response_data)
    val(name)

    output:
    path '{models,baselines}*.txt',    emit: all_models
    tuple val("${task.process}"), val('python'), eval("python --version | sed 's/Python //g'"), topic: versions, emit: versions_python
    tuple val("${task.process}"), val('drevalpy'), eval("drevalpy --version | sed 's/drevalpy //'"), topic: versions, emit: versions_drevalpy
    tuple val("${task.process}"), val('sklearn'), eval("python -c \"import sklearn; print(sklearn.__version__)\""), topic: versions, emit: versions_sklearn
    tuple val("${task.process}"), val('numpy'), eval("python -c \"import numpy; print(numpy.__version__)\""), topic: versions, emit: versions_numpy
    tuple val("${task.process}"), val('pandas'), eval("python -c \"import pandas; print(pandas.__version__)\""), topic: versions, emit: versions_pandas
    tuple val("${task.process}"), val('pytorch_lightning'), eval("python -c \"import pytorch_lightning; print(pytorch_lightning.__version__)\""), topic: versions, emit: versions_pytorch_lightning
    tuple val("${task.process}"), val('torch'), eval("python -c \"import torch; print(torch.__version__)\" | sed 's/+.*//'"), topic: versions, emit: versions_torch

    script:
    """
    make_model_channel.py \\
        --models "${models}" \\
        --data ${response_data} \\
        --file_name ${name}
    """

}
