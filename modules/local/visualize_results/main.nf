process VISUALIZE_RESULTS {
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/25/258ae8d4dc806d30de817bb11421fb2316bdb3dd3305dfaa37e5ea01eb475341/data' :
        'community.wave.seqera.io/library/python_pip_drevalpy:8252ebecce29d755' }"

    input:
    tuple path(eval_results), path(eval_results_per_drug), path(eval_results_per_cl), path(true_vs_predicted)
    val(path_data)

    output:
    path('report/*'),                           emit: html_out
    path("versions.yml"),                       emit: versions


    script:
    """
    drevalpy-make-pipeline-report \\
        --test_modes ${params.test_mode.replace(',', ' ')} \\
        --eval_results $eval_results \\
        --eval_results_per_drug $eval_results_per_drug \\
        --eval_results_per_cl $eval_results_per_cl \\
        --true_vs_predicted $true_vs_predicted \\
        --path_data $path_data

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(python -c "import drevalpy; print(drevalpy.__version__)")
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
        matplotlib: \$(python -c "import matplotlib; print(matplotlib.__version__)")
        scikit_posthocs: \$(python -c "import scikit_posthocs; print(scikit_posthocs.__version__)")
        scipy: \$(python -c "import scipy; print(scipy.__version__)")
        sklearn: \$(python -c "import sklearn; print(sklearn.__version__)")
    END_VERSIONS
    """

}
