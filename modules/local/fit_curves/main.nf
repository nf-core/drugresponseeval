process FIT_CURVES {
    //tag "$samplesheet"
    label 'process_medium'
    publishDir "${path_data}", mode: 'copy'


    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"

    input:
    val dataset_name
    val path_data
    val curve_curator_input

    script:
    """
    prepost_curvefitting.py \\
        --input=$curve_curator_input \\
        --output_dir=$path_data/$dataset_name
        --cores=50
    CurveCurator $path_data/$dataset_name/config.toml --mad
    prepost_curvefitting.py --output_dir=$path_data/$dataset_name
    """
}
