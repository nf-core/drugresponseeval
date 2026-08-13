
process AGGREGATE {
    tag "aggregate"
    label 'process_medium'

    container 'docker.io/nicotru/drevalpy:latest'

    input:
    path(results, stageAs: 'results/results_?.npz')

    output:
    path("aggregated/"), emit: experiment

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    export XDG_CACHE_HOME=./cache/
    export XDG_CONFIG_HOME=./config/
    # Unbuffered stdout so the last progress line survives an OOM SIGKILL.
    export PYTHONUNBUFFERED=1
    drevalpy aggregate results/*.npz --output-dir aggregated
    """

    stub:
    """
    mkdir -p aggregated
    touch aggregated/aggregated.npz
    """
}
