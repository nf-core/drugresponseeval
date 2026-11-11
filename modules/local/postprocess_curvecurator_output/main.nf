process POSTPROCESS_CURVECURATOR_DATA {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "matplotlib_numpy_pandas_python_pruned:4ca8e30ab27649ab"

    input:
    val dataset_name
    path(curve_data, stageAs: "?/*")
    val measure

    output:
    path "${dataset_name}.csv", emit: path_to_dataset
    val "${measure}" + "_curvecurator", emit: measure
    tuple val("${task.process}"), val('python'), eval("python --version | sed 's/Python //g'"), topic: versions, emit: versions_python
    tuple val("${task.process}"), val('drevalpy'), eval("drevalpy --version | sed 's/drevalpy //'"), topic: versions, emit: versions_drevalpy

    script:
    """
    drevalpy viability-postprocess --dataset_name ${dataset_name}
    """
}
