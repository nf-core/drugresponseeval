process TUNE_FINAL_MODEL {
    tag { "${model_name}_${test_mode}" }
    label 'process_high'
    label 'process_gpu'

    conda "${moduleDir}/environment.yml"
    container "matplotlib_numpy_pandas_python_pruned:4ca8e30ab27649ab"

    input:
    tuple val(model_name), path(train_ds), path(val_ds), path(early_stop_ds), val(test_mode), path(path_data), path(hpam_combi)
    val response_transformation
    val model_checkpoint_dir

    output:
    tuple val(model_name), val(test_mode), val("final"), path(hpam_combi), path("final_prediction_dataset_*.pkl"),  emit: final_prediction
    tuple val("${task.process}"), val('python'), eval("python --version | sed 's/Python //g'"), topic: versions, emit: versions_python
    tuple val("${task.process}"), val('drevalpy'), eval("drevalpy --version | sed 's/drevalpy //'"), topic: versions, emit: versions_drevalpy
    tuple val("${task.process}"), val('sklearn'), eval("python -c \"import sklearn; print(sklearn.__version__)\""), topic: versions, emit: versions_sklearn
    tuple val("${task.process}"), val('numpy'), eval("python -c \"import numpy; print(numpy.__version__)\""), topic: versions, emit: versions_numpy
    tuple val("${task.process}"), val('pandas'), eval("python -c \"import pandas; print(pandas.__version__)\""), topic: versions, emit: versions_pandas
    tuple val("${task.process}"), val('pytorch_lightning'), eval("python -c \"import pytorch_lightning; print(pytorch_lightning.__version__)\""), topic: versions, emit: versions_pytorch_lightning
    tuple val("${task.process}"), val('torch'), eval("python -c \"import torch; print(torch.__version__)\" | sed 's/+.*//'"), topic: versions, emit: versions_torch

    script:
    """
    drevalpy tune-final-model \\
        --train_data $train_ds \\
        --val_data $val_ds \\
        --early_stopping_data $early_stop_ds \\
        --model_name "${model_name}" \\
        --hpam_combi $hpam_combi \\
        --response_transformation $response_transformation \\
        --path_data $path_data \\
        --model_checkpoint_dir $model_checkpoint_dir
    """
}
