process ROBUSTNESS_TEST {
    tag { "${model_name}_${robustness_iteration}_gpu:${task.ext.use_gpu}" }
    label 'process_high'
    label 'process_gpu'
    publishDir "${params.outdir}/${params.run_id}/${test_mode}", mode: 'copy'

    input:
    tuple val(model_name), val(test_mode), val(split_id), path(split_dataset), path(best_hpams), val(robustness_iteration), path(path_data)
    val(randomization_type)
    val(response_transformation)
    val model_checkpoint_dir

    output:
    tuple val(test_mode), val(model_name), path('**robustness*.csv'),     emit: ch_vis
    path("versions.yml"),                       emit: versions

    script:
    """
    train_and_predict_final.py \\
        --mode robustness \\
        --model_name "${model_name}" \\
        --split_id $split_id \\
        --split_dataset_path $split_dataset \\
        --hyperparameters_path $best_hpams \\
        --response_transformation $response_transformation \\
        --test_mode $test_mode \\
        --path_data $path_data \\
        --robustness_trial $robustness_iteration \\
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
