process PREPROCESS_RAW_VIABILITY {
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/90/908156ca5b3770a1797cd6f564cea34935ab7b09b39643436494f3bdf6331266/data' :
        'community.wave.seqera.io/library/matplotlib_numpy_pandas_python_pruned:0868f8788117e11b' }"

    input:
    val(dataset_name)
    path(work_path)

    output:
    path "${dataset_name}/*/config.toml", emit: path_to_toml
    path "${dataset_name}/*/curvecurator_input.tsv", emit: curvecurator_input
    path("versions.yml"),                       emit: versions

    script:
    """
    drevalpy-viability-preprocess --path_data ${work_path} --dataset_name ${dataset_name} --cores ${task.cpus}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(python -c "import drevalpy; print(drevalpy.__version__)")
    END_VERSIONS
    """
}
