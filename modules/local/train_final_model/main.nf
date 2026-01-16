process TRAIN_FINAL_MODEL {
    tag { "${model_name}_${test_mode}_gpu:${task.ext.use_gpu}" }
    label 'process_high'
    label 'process_gpu'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/88/88d06bd843a342074e5def5c95e7d993cfe4a7f0acb7c41eb6c00e78d9ce8654/data'
        : 'python_pip_drevalpy:a2b7a0d499377204'}"

    input:
    tuple val(model_name), val(test_mode), path(best_hpam_combi), path(train_data), path(val_data), path(early_stop_data), path(path_data)
    val response_transformation
    val model_checkpoint_dir


    output:
    path("**final_model/*"),                      emit: final_model
    path("versions.yml"),                       emit: versions

    script:
    """
    drevalpy-train-final-model \\
        --train_data $train_data \\
        --val_data $val_data \\
        --early_stopping_data $early_stop_data \\
        --response_transformation "${response_transformation}" \\
        --model_name "${model_name}" \\
        --path_data $path_data \\
        --model_checkpoint_dir $model_checkpoint_dir \\
        --best_hpam_combi $best_hpam_combi


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
