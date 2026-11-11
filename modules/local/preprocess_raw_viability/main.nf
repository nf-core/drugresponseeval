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
    tuple val("${task.process}"), val('python'), eval("python --version | sed 's/Python //g'"), topic: versions, emit: versions_python
    tuple val("${task.process}"), val('drevalpy'), eval("drevalpy --version | sed 's/drevalpy //'"), topic: versions, emit: versions_drevalpy

    script:
    """
    drevalpy viability-preprocess --path_data ${work_path} --dataset_name ${dataset_name} --cores ${task.cpus}
    """
}
