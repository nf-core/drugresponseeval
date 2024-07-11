process PREDICT_FULL {
    tag "${test_mode}_${model_name}_${split_id}"
    label 'process_single'
    publishDir "${params.outdir}/${params.run_id}/${test_mode}/${model_name}/predictions"

    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"
    input:
    tuple val(split_id), val(test_mode), path(split_dataset), val(model_name), path(hpam_combi)
    val(response_transformation)
    val(path_data)

    output:
    tuple val(test_mode), val(model_name), path('predictions_*.csv'),     emit: ch_vis

    script:
    """
    train_and_predict_final.py \\
        --mode full \\
        --model_name $model_name \\
        --split_id $split_id \\
        --split_dataset_path $split_dataset \\
        --hyperparameters_path $hpam_combi \\
        --response_transformation $response_transformation \\
        --test_mode $test_mode \\
        --path_data $path_data
    """

}
