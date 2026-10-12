process PREDICT_FULL {
    tag { "${test_mode}_${model_name}_${split_id}" }
    label 'process_high'
    label 'process_gpu'

    conda "${moduleDir}/environment.yml"
    container "matplotlib_numpy_pandas_python_pruned:4ca8e30ab27649ab"

    input:
    tuple path(cross_study_datasets), val(model_name), val(test_mode), val(split_id), path(split_dataset), path(hpam_combi), path(path_data)
    val(response_transformation)
    val(model_checkpoint_dir)

    output:
    tuple val(test_mode), val(model_name), path('**predictions*.csv'), emit: ch_vis
    tuple val(test_mode), val(model_name), path('**cross_study/cross_study*.csv'),   emit: ch_cross, optional: true
    path('**best_hpams*.json'),             emit: ch_hpams
    tuple val("${task.process}"), val('python'), eval("python --version | sed 's/Python //g'"), topic: versions, emit: versions_python
    tuple val("${task.process}"), val('drevalpy'), eval("drevalpy --version | sed 's/drevalpy //'"), topic: versions, emit: versions_drevalpy
    tuple val("${task.process}"), val('sklearn'), eval("python -c \"import sklearn; print(sklearn.__version__)\""), topic: versions, emit: versions_sklearn
    tuple val("${task.process}"), val('numpy'), eval("python -c \"import numpy; print(numpy.__version__)\""), topic: versions, emit: versions_numpy
    tuple val("${task.process}"), val('pandas'), eval("python -c \"import pandas; print(pandas.__version__)\""), topic: versions, emit: versions_pandas
    tuple val("${task.process}"), val('pytorch_lightning'), eval("python -c \"import pytorch_lightning; print(pytorch_lightning.__version__)\""), topic: versions, emit: versions_pytorch_lightning
    tuple val("${task.process}"), val('torch'), eval("python -c \"import torch; print(torch.__version__)\" | sed 's/+.*//'"), topic: versions, emit: versions_torch

    script:
    """
    drevalpy test-cv \\
        --mode full \\
        --model_name "${model_name}" \\
        --split_id $split_id \\
        --split_dataset_path $split_dataset \\
        --hyperparameters_path $hpam_combi \\
        --response_transformation $response_transformation \\
        --test_mode $test_mode \\
        --path_data $path_data \\
        --cross_study_datasets $cross_study_datasets \\
        --model_checkpoint_dir $model_checkpoint_dir \\
    """

}
