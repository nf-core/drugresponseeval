process PARAMS_CHECK {
    //tag "$samplesheet"
    //label 'process_single'

    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"

    input:
    val models
    val test_mode
    val dataset_name
    val n_cv_splits
    val randomization_mode
    val curve_curator
    val response_transformation
    val optim_metric

    output:

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in nf-core/drugresponseeval/bin/
    """
    check_params.py \\
        --models $models \\
        --test_mode $test_mode \\
        --dataset_name $dataset_name \\
        --n_cv_splits $n_cv_splits \\
        --randomization_mode $randomization_mode \\
        --curve_curator $curve_curator \\
        --response_transformation $response_transformation \\
        --optim_metric $optim_metric
    """
}
