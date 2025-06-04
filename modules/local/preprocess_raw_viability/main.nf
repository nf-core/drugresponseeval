process PREPROCESS_RAW_VIABILITY {
    label 'process_low'

    input:
    val(dataset_name)
    path(work_path)
    val useless_count

    output:
    path "${dataset_name}/*/config.toml", emit: path_to_toml
    path "${dataset_name}/*/curvecurator_input.tsv", emit: curvecurator_input
    path("versions.yml"),                       emit: versions

    script:
    """
    preprocess_raw_viability.py --path_data ${work_path} --dataset_name ${dataset_name} --cores ${task.cpus}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(python -c "import drevalpy; print(drevalpy.__version__)")
    END_VERSIONS
    """
}
