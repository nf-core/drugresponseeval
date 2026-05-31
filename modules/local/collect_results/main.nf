process COLLECT_RESULTS {
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/25/258ae8d4dc806d30de817bb11421fb2316bdb3dd3305dfaa37e5ea01eb475341/data' :
        'community.wave.seqera.io/library/python_pip_drevalpy:8252ebecce29d755' }"


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
