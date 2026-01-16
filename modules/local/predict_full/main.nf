process PREDICT_FULL {
    tag { "${test_mode}_${model_name}_${split_id}_gpu:${task.ext.use_gpu}" }
    label 'process_high'
    label 'process_gpu'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/88/88d06bd843a342074e5def5c95e7d993cfe4a7f0acb7c41eb6c00e78d9ce8654/data'
        : 'python_pip_drevalpy:a2b7a0d499377204'}"

    input:
    tuple path(cross_study_datasets), val(model_name), val(test_mode), val(split_id), path(split_dataset), path(hpam_combi), path(path_data)
    val(response_transformation)
    val(model_checkpoint_dir)

    output:
    tuple val(test_mode), val(model_name), path('**predictions*.csv'), emit: ch_vis
    tuple val(test_mode), val(model_name), path('**cross_study/cross_study*.csv'),   emit: ch_cross, optional: true
    path('**best_hpams*.json'),             emit: ch_hpams
    path("versions.yml"),                       emit: versions

    script:
    """
    drevalpy-test-cv \\
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
