process RANDOMIZATION_SPLIT {
    tag "${model_name}_${randomization_mode}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "matplotlib_numpy_pandas_python_pruned:4ca8e30ab27649ab"

    input:
    tuple val(model_name), val(randomization_mode)

    output:
    tuple val(model_name), path('randomization_test_view*.yaml'),     emit: randomization_test_views
    tuple val("${task.process}"), val('python'), eval("python --version | sed 's/Python //g'"), topic: versions, emit: versions_python
    tuple val("${task.process}"), val('drevalpy'), eval("drevalpy --version | sed 's/drevalpy //'"), topic: versions, emit: versions_drevalpy
    tuple val("${task.process}"), val('sklearn'), eval("python -c \"import sklearn; print(sklearn.__version__)\""), topic: versions, emit: versions_sklearn
    tuple val("${task.process}"), val('numpy'), eval("python -c \"import numpy; print(numpy.__version__)\""), topic: versions, emit: versions_numpy
    tuple val("${task.process}"), val('pandas'), eval("python -c \"import pandas; print(pandas.__version__)\""), topic: versions, emit: versions_pandas
    tuple val("${task.process}"), val('pytorch_lightning'), eval("python -c \"import pytorch_lightning; print(pytorch_lightning.__version__)\""), topic: versions, emit: versions_pytorch_lightning
    tuple val("${task.process}"), val('torch'), eval("python -c \"import torch; print(torch.__version__)\""), topic: versions, emit: versions_torch
    tuple val("${task.process}"), val('yaml'), eval("python -c \"import yaml; print(yaml.__version__)\""), topic: versions, emit: versions_yaml

    script:
    """
    drevalpy make-randomization-yamls --model_name "${model_name}" --randomization_mode ${randomization_mode}
    """

}
