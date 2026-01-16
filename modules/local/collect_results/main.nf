process COLLECT_RESULTS {
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/88/88d06bd843a342074e5def5c95e7d993cfe4a7f0acb7c41eb6c00e78d9ce8654/data'
        : 'python_pip_drevalpy:a2b7a0d499377204'}"


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
    drevalpy-collect-results \\
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
