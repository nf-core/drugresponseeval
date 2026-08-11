
process AGGREGATE {
    tag "aggregate"
    label 'process_single'

    container 'docker.io/nicotru/drevalpy:latest'

    input:
    path(results)
    val(output_dir)

    output:
    path("$output_dir/**"), emit: experiment

    when:
    task.ext.when == null || task.ext.when

    script:
    def result_args = results.collect { it.toString() }.join(' ')
    """
    drevalpy aggregate $result_args --output-dir $output_dir
    """
}
