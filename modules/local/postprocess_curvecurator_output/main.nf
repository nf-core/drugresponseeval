process POSTPROCESS_CURVECURATOR_DATA {
    //tag "$samplesheet"
    label 'process_low'
    publishDir "${path_data}/${dataset_name}/", mode: 'copy'


    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"

    input:
    val dataset_name
    path curve_data

    output:
    path "${dataset_name}.csv", emit: path_to_dataset

    script:
    """
    postprocess_curvecurator_output.py --dataset_name ${dataset_name}
    """
}
