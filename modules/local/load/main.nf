
process LOAD {
    tag "$dataset"
    label 'process_single'

    container 'docker.io/nicotru/drevalpy:latest'

    input:
    val(dataset)

    output:
    path('*.h5mu')

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    drevalpy load 
    """
}
