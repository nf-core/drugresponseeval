process POSTPROCESS_CURVECURATOR_DATA {
    label 'process_single'
    publishDir "${params.path_data}/${dataset_name}", mode: 'copy'

    input:
    val dataset_name
    path(curve_data, stageAs: "?/*")
    val measure

    output:
    path "${dataset_name}.csv", emit: path_to_dataset
    val "${measure}" + "_curvecurator", emit: measure

    script:
    """
    postprocess_curvecurator_output.py --dataset_name ${dataset_name}
    """
}
