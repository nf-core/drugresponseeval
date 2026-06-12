process PREPROCESS_RAW_VIABILITY {
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "matplotlib_numpy_pandas_python_pruned:4ca8e30ab27649ab"

    input:
    val(dataset_name)
    path(work_path)

    output:
    path "${dataset_name}/*/config.toml", emit: path_to_toml
    path "${dataset_name}/*/curvecurator_input.tsv", emit: curvecurator_input
    path("versions.yml"),                       emit: versions

    script:
    """
    drevalpy viability-preprocess --path_data ${work_path} --dataset_name ${dataset_name} --cores ${task.cpus}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(drevalpy --version | sed 's/drevalpy //g')
    END_VERSIONS
    """
}
