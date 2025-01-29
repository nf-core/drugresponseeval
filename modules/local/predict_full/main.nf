process PREDICT_FULL {
    tag { "${test_mode}_${model_name}_${split_id}_gpu:${task.ext.use_gpu}" }
    label 'process_high'
    label 'process_gpu'
    publishDir "${params.outdir}/${params.run_id}/${test_mode}", mode: 'copy'

    input:
    tuple path(cross_study_datasets), val(model_name), val(test_mode), val(split_id), path(split_dataset), path(hpam_combi), path(path_data)
    val(response_transformation)
    val(model_checkpoint_dir)

    output:
    tuple val(test_mode), val(model_name), path('**predictions*.csv'), emit: ch_vis
    path('**cross_study/cross_study*.csv'),   emit: ch_cross, optional: true
    path('**best_hpams*.json'),             emit: ch_hpams

    script:
    """
    train_and_predict_final.py \\
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
