process PARAMS_CHECK {
    //tag "$samplesheet"
    label 'process_single'

    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"

    input:
    val run_id
    val models
    val baselines
    val test_mode
    val randomization_mode
    val randomization_type
    val n_trials_robustness
    val dataset_name
    val cross_study_datasets
    val curve_curator
    val optim_metric
    val n_cv_splits
    val response_transformation

    output:


    when:
    task.ext.when == null || task.ext.when

    script:
    """
    check_params.py \\
        --run_id $run_id \\
        --models ${models.replace(',', ' ')} \\
        --baselines ${baselines.replace(',', ' ')} \\
        --test_mode ${test_mode.replace(',', ' ')} \\
        --randomization_mode ${randomization_mode.replace(',', ' ')} \\
        --randomization_type $randomization_type \\
        --n_trials_robustness $n_trials_robustness \\
        --dataset_name $dataset_name \\
        ${cross_study_datasets != '' ? '--cross_study_datasets ' + cross_study_datasets.replace(',', ' ') : ''} \\
        ${curve_curator ? '--curve_curator' : ''} \\
        --optim_metric $optim_metric \\
        --n_cv_splits $n_cv_splits \\
        --response_transformation $response_transformation
    """
}
