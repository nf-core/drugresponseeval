process FIT_CURVES {
    //tag "$samplesheet"
    label 'high_cpu_low_mem'
    publishDir "${path_data}", mode: 'copy'


    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"

    input:
    val dataset_name
    val path_data

    output:
    path '${dataset_name}/config.toml'
    path '${dataset_name}/curves.txt'
    path '${dataset_name}/${dataset_name}.csv'

    script:
    """
    prepost_curve_fitting.py --path_data=$path_data --dataset_name=$dataset_name --task=preprocess --cores=$task.cpus
    CurveCurator $path_data/$dataset_name/config.toml --mad
    prepost_curve_fitting.py --path_data=$path_data --dataset_name=$dataset_name --task=postprocess
    """
}
