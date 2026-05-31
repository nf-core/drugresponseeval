process TUNE_FINAL_MODEL {
    tag { "${model_name}_${test_mode}_gpu:${task.ext.use_gpu}" }
    label 'process_high'
    label 'process_gpu'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/90/908156ca5b3770a1797cd6f564cea34935ab7b09b39643436494f3bdf6331266/data' :
        'community.wave.seqera.io/library/matplotlib_numpy_pandas_python_pruned:0868f8788117e11b' }"

    input:
    tuple val(model_name), path(train_ds), path(val_ds), path(early_stop_ds), val(test_mode), path(path_data), path(hpam_combi)
    val response_transformation
    val model_checkpoint_dir

    output:
    tuple val(model_name), val(test_mode), val("final"), path(hpam_combi), path("final_prediction_dataset_*.pkl"),  emit: final_prediction
    path("versions.yml"),                                                                                           emit: versions

    script:
    """
    drevalpy-tune-final-model \\
        --train_data $train_ds \\
        --val_data $val_ds \\
        --early_stopping_data $early_stop_ds \\
        --model_name "${model_name}" \\
        --hpam_combi $hpam_combi \\
        --response_transformation $response_transformation \\
        --path_data $path_data \\
        --model_checkpoint_dir $model_checkpoint_dir


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(python -c "import drevalpy; print(drevalpy.__version__)")
        sklearn: \$(python -c "import sklearn; print(sklearn.__version__)")
        numpy: \$(python -c "import numpy; print(numpy.__version__)")
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
        pytorch_lightning: \$(python -c "import pytorch_lightning; print(pytorch_lightning.__version__)")
        torch: \$(python -c "import torch; print(torch.__version__)" | sed 's/+.*//')
        platform: \$(python -c "import platform; print(platform.__version__)")
    END_VERSIONS
    """
}
