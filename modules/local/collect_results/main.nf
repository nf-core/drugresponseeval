process COLLECT_RESULTS {
    label 'process_medium'



    input:
    path(outfiles)
    path(path_data)

    output:
    path('evaluation_results.csv'), emit: evaluation_results
    path('evaluation_results_per_drug.csv'), emit: evaluation_results_per_drug, optional: true
    path('evaluation_results_per_cl.csv'), emit: evaluation_results_per_cl, optional: true
    path('true_vs_pred.csv'), emit: true_vs_pred
    path("versions.yml"),                       emit: versions

    script:
    """
    collect_results.py \\
        --outfiles $outfiles \\
        --path_data $path_data

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(python -c "import drevalpy; print(drevalpy.__version__)")
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
    END_VERSIONS
    """

}
