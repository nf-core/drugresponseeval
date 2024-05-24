process CV_SPLIT {
    tag "$test_mode"
    label 'process_single'

    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"
    input:
    tuple val(test_mode), path(response)
    val n_cv_splits

    output:
    tuple val(test_mode), path("split*.pkl")    , emit: response_cv_splits


    script:
    """
    cv_split.py \\
        --response $response \\
        --n_cv_splits $n_cv_splits \\
        --test_mode $test_mode
    """

}
