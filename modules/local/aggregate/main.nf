
process AGGREGATE {
    tag "aggregate"
    label 'process_single'

    container 'docker.io/nicotru/drevalpy:latest'

    input:
    path(results, stageAs: 'results/results_?.npz')

    output:
    path("aggregated/"), emit: experiment

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    drevalpy aggregate $results --output-dir aggregated
    """

    stub:
    """
    mkdir -p aggregated
    touch aggregated/aggregated.npz
    """
}
