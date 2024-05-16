process EVALUATE {
    //tag "$samplesheet"
    //label 'process_single'

    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"
    input:
    val pred_data
    val metric
    tuple val(model_name), path(cv_data)

    output:
    path "*.pkl"    , emit: eval_results
    tuple val(model_name), path(cv_data), emit: meta


    script:
    """
    evaluate.py \\
        --pred_data $pred_data \\
        --metric $metric
    """

}
