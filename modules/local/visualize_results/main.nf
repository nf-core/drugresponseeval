process VISUALIZE_RESULTS {
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "matplotlib_numpy_pandas_python_pruned:4ca8e30ab27649ab"

    input:
    tuple path(eval_results), path(eval_results_per_drug), path(eval_results_per_cl), path(true_vs_predicted)
    val(path_data)

    output:
    path('report/*'),                           emit: html_out
    tuple val("${task.process}"), val('python'), eval("python --version | sed 's/Python //g'"), topic: versions, emit: versions_python
    tuple val("${task.process}"), val('drevalpy'), eval("drevalpy --version | sed 's/drevalpy //'"), topic: versions, emit: versions_drevalpy
    tuple val("${task.process}"), val('pandas'), eval("python -c \"import pandas; print(pandas.__version__)\""), topic: versions, emit: versions_pandas
    tuple val("${task.process}"), val('matplotlib'), eval("python -c \"import matplotlib; print(matplotlib.__version__)\""), topic: versions, emit: versions_matplotlib
    tuple val("${task.process}"), val('scikit_posthocs'), eval("python -c \"import scikit_posthocs; print(scikit_posthocs.__version__)\""), topic: versions, emit: versions_scikit_posthocs
    tuple val("${task.process}"), val('scipy'), eval("python -c \"import scipy; print(scipy.__version__)\""), topic: versions, emit: versions_scipy
    tuple val("${task.process}"), val('sklearn'), eval("python -c \"import sklearn; print(sklearn.__version__)\""), topic: versions, emit: versions_sklearn


    script:
    """
    drevalpy make-pipeline-report \\
        --test_modes ${params.test_mode.replace(',', ' ')} \\
        --eval_results $eval_results \\
        --eval_results_per_drug $eval_results_per_drug \\
        --eval_results_per_cl $eval_results_per_cl \\
        --true_vs_predicted $true_vs_predicted \\
        --path_data $path_data
    """

}
