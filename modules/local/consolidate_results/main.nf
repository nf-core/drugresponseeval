process CONSOLIDATE_RESULTS {
    tag "$model_name"
    label 'process_single'
    publishDir "${params.outdir}/${params.run_id}/${test_mode}", mode: 'copy'

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
    consolidate_results.py \\
        --run_id ${params.run_id} \\
        --test_mode ${test_mode} \\
        --model_name "${model_name}" \\
        --outdir_path ${outdirPath} \\
        --n_cv_splits ${params.n_cv_splits} \\
        ${params.cross_study_datasets != '' ? '--cross_study_datasets ' + params
        .cross_study_datasets.replace(',', ' ') : ''} \\
        --randomization_modes ${rand_modes}\\
        --n_trials_robustness ${params.n_trials_robustness}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(python -c "import drevalpy; print(drevalpy.__version__)")
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
    END_VERSIONS
    """
}
