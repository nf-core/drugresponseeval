process CONSOLIDATE_RESULTS {
    tag "$model_name"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/25/258ae8d4dc806d30de817bb11421fb2316bdb3dd3305dfaa37e5ea01eb475341/data' :
        'community.wave.seqera.io/library/python_pip_drevalpy:8252ebecce29d755' }"

    input:
    tuple val(test_mode), val(model_name)
    val(rand_modes)
    val(nr_files)

    output:
    tuple val(test_mode), val(model_name), path('**split*.csv'), emit: ch_vis, optional: true
    path("versions.yml"),                       emit: versions

    script:
    def outdirPath = new File(params.outdir).getAbsolutePath()
    """
    drevalpy-consolidate-single-drug \\
        --run_id ${params.run_id} \\
        --test_mode ${test_mode} \\
        --model_name "${model_name}" \\
        --outdir_path ${outdirPath} \\
        --n_cv_splits ${params.n_cv_splits} \\
        ${params.cross_study_datasets != '' ? '--cross_study_datasets ' + params
        .cross_study_datasets.replace(',', ' ') : ''} \\
        --randomization_modes "${rand_modes}"\\
        --n_trials_robustness ${params.n_trials_robustness}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(python -c "import drevalpy; print(drevalpy.__version__)")
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
    END_VERSIONS
    """
}
