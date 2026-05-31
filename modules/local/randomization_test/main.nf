process RANDOMIZATION_TEST {
    tag { "${test_mode}_${model_name}_${randomization_type}_gpu:${task.ext.use_gpu}" }
    label 'process_high'
    label 'process_gpu'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/25/258ae8d4dc806d30de817bb11421fb2316bdb3dd3305dfaa37e5ea01eb475341/data' :
        'community.wave.seqera.io/library/python_pip_drevalpy:8252ebecce29d755' }"

    input:
    tuple val(model_name), val(test_mode), val(split_id), path(split_dataset), path(best_hpams), path(randomization_views), path(path_data)
    val(randomization_type)
    val(response_transformation)
    val model_checkpoint_dir

    output:
    tuple val(test_mode), val(model_name), path('**randomization*.csv'),     emit: ch_vis
    path("versions.yml"),                       emit: versions

    script:
    """
    drevalpy-test-cv \\
        --mode randomization \\
        --model_name "${model_name}" \\
        --split_id $split_id \\
        --split_dataset_path $split_dataset \\
        --hyperparameters_path $best_hpams \\
        --response_transformation $response_transformation \\
        --test_mode $test_mode \\
        --path_data $path_data \\
        --randomization_views_path $randomization_views \\
        --randomization_type $randomization_type \\
        --model_checkpoint_dir $model_checkpoint_dir \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(python -c "import drevalpy; print(drevalpy.__version__)")
        sklearn: \$(python -c "import sklearn; print(sklearn.__version__)")
        numpy: \$(python -c "import numpy; print(numpy.__version__)")
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
        pytorch_lightning: \$(python -c "import pytorch_lightning; print(pytorch_lightning.__version__)")
        torch: \$(python -c "import torch; print(torch.__version__)")
        platform: \$(python -c "import platform; print(platform.__version__)")
    END_VERSIONS
    """

}
