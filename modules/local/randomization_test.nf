process RANDOMIZATION_TEST {
    tag "${test_mode}_${model_name}_${randomization_type}"
    label 'process_single'
    publishDir "${params.outdir}/${params.run_id}/${test_mode}/${model_name}/randomization_test"

    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"
    input:
    tuple val(model_name), val(test_mode), val(split_id), path(split_dataset), path(best_hpams), path(randomization_views)
    path(path_data)
    val(randomization_type)
    val(response_transformation)

    output:
    path('randomization_*.csv'),     emit: test_dataset

    script:
    """
    train_and_predict_final.py \\
        --mode randomization \\
        --model_name $model_name \\
        --split_id $split_id \\
        --split_dataset_path $split_dataset \\
        --hyperparameters_path $best_hpams \\
        --response_transformation $response_transformation \\
        --test_mode $test_mode \\
        --path_data $path_data \\
        --randomization_views_path $randomization_views \\
        --randomization_type $randomization_type
    """

}
