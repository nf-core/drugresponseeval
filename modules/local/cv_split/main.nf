process CV_SPLIT {
    tag "$test_mode"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "matplotlib_numpy_pandas_python_pruned:4ca8e30ab27649ab"

    input:
    tuple val(test_mode), path(response)
    val n_cv_splits
    path custom_splitter

    output:
    tuple val(test_mode), path("split*.pkl")    , emit: response_cv_splits
    tuple val("${task.process}"), val('python'), eval("python --version | sed 's/Python //g'"), topic: versions, emit: versions_python
    tuple val("${task.process}"), val('drevalpy'), eval("drevalpy --version | sed 's/drevalpy //'"), topic: versions, emit: versions_drevalpy
    tuple val("${task.process}"), val('sklearn'), eval("python -c \"import sklearn; print(sklearn.__version__)\""), topic: versions, emit: versions_sklearn
    tuple val("${task.process}"), val('numpy'), eval("python -c \"import numpy; print(numpy.__version__)\""), topic: versions, emit: versions_numpy


    script:
    def splitter_arg = custom_splitter.name != 'NO_FILE' ? "--custom_splitter_path $custom_splitter" : ''
    """
    drevalpy make-cv-pkls \\
        --response $response \\
        --n_cv_splits $n_cv_splits \\
        --test_mode $test_mode \\
        $splitter_arg
    """

}
