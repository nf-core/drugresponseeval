
process REPORT {
    tag "report"
    label 'process_single'

    container 'docker.io/nicotru/drevalpy:latest'

    input:
    path(experiment_dir)
    val(output_dir)
    val(title)
    val(reference_model)
    path(dataset_path)

    output:
    path("$output_dir/**"), emit: report

    when:
    task.ext.when == null || task.ext.when

    script:
    def ref_flag = reference_model ? "--reference-model $reference_model" : ''
    def ds_flag = dataset_path.name != 'NO_FILE' ? "--dataset $dataset_path" : ''
    """
    drevalpy report $experiment_dir --output-dir $output_dir --title "$title" $ref_flag $ds_flag
    """
}
