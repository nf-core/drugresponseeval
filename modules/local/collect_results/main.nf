process COLLECT_RESULTS {
    //tag "${test_mode}_${model_name}_${pred_file}"
    label 'process_single'
    publishDir "${params.outdir}/${params.run_id}"

    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"

    input:
    path(outfiles)

    output:
    path('evaluation_results.csv'), emit: evaluation_results
    path('evaluation_results_per_drug.csv'), emit: evaluation_results_per_drug
    path('evaluation_results_per_cl.csv'), emit: evaluation_results_per_cl
    path('true_vs_pred.csv'), emit: true_vs_pred

    script:
    """
    collect_results.py \\
        --outfiles $outfiles
    """

}
