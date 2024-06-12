process PARSE_RESULTS {
    //tag "${test_mode}_${model_name}_${split_id}"
    label 'process_single'
    publishDir "${params.outdir}/${params.run_id}"

    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"

    input:
    path(outfiles)
    val(run_id)
    val(outdir)

    output:
    path('evaluation_*.csv'),     emit: all_results

    script:
    """
    #!/usr/bin/env python
    import os
    from drevalpy.visualization.utils import prep_results
    prep_results(path_to_results="${outdir}/${run_id}", path_out="")
    """

}
