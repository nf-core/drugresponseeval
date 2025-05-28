process PARAMS_CHECK {
    label 'process_single'

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
    val no_refitting
    val optim_metric
    val n_cv_splits
    val response_transformation
    val path_data
    val measure

    output:
    val path_data

    script:
    def work_path = new File("${path_data}").absolutePath
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
        ${no_refitting ? '--no_refitting' : '--curve_curator_cores 1'} \\
        --path_data $work_path \\
        --measure $measure \\
        --optim_metric $optim_metric \\
        --n_cv_splits $n_cv_splits \\
        --response_transformation $response_transformation \\
    """
}
