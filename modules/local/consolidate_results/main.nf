process CONSOLIDATE_RESULTS {
    tag "$model_name"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "matplotlib_numpy_pandas_python_pruned:4ca8e30ab27649ab"

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
    drevalpy consolidate-single-drug \\
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
        drevalpy: \$(drevalpy --version | sed 's/drevalpy //g')
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
    END_VERSIONS
    """
}
