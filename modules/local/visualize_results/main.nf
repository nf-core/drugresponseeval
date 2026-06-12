process VISUALIZE_RESULTS {
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "matplotlib_numpy_pandas_python_pruned:4ca8e30ab27649ab"

    input:
    tuple path(eval_results), path(eval_results_per_drug), path(eval_results_per_cl), path(true_vs_predicted)
    val(path_data)

    output:
    path('report/*'),                           emit: html_out
    path("versions.yml"),                       emit: versions


    script:
    """
    drevalpy make-pipeline-report \\
        --test_modes ${params.test_mode.replace(',', ' ')} \\
        --eval_results $eval_results \\
        --eval_results_per_drug $eval_results_per_drug \\
        --eval_results_per_cl $eval_results_per_cl \\
        --true_vs_predicted $true_vs_predicted \\
        --path_data $path_data

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(drevalpy --version | sed 's/drevalpy //g')
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
        matplotlib: \$(python -c "import matplotlib; print(matplotlib.__version__)")
        scikit_posthocs: \$(python -c "import scikit_posthocs; print(scikit_posthocs.__version__)")
        scipy: \$(python -c "import scipy; print(scipy.__version__)")
        sklearn: \$(python -c "import sklearn; print(sklearn.__version__)")
    END_VERSIONS
    """

}
