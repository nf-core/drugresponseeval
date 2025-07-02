process CV_SPLIT {
    tag "$test_mode"
    label 'process_single'



    input:
    tuple val(test_mode), path(response)
    val n_cv_splits

    output:
    tuple val(test_mode), path("split*.pkl")    , emit: response_cv_splits
    path("versions.yml"),                       emit: versions


    script:
    """
    cv_split.py \\
        --response $response \\
        --n_cv_splits $n_cv_splits \\
        --test_mode $test_mode

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(python -c "import drevalpy; print(drevalpy.__version__)")
        sklearn: \$(python -c "import sklearn; print(sklearn.__version__)")
        numpy: \$(python -c "import numpy; print(numpy.__version__)")
    END_VERSIONS
    """

}
