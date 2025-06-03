process UNZIP {
    tag "${dataset_name}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/unzip:6.0--2d90c8369f967b58' :
        'community.wave.seqera.io/library/unzip:6.0--0e729f0c20458893' }"

    input:
    tuple val(dataset_name), path(file)

    output:
    tuple val(dataset_name), path("${file.baseName}/"), path("${file.baseName}/${file.baseName}.csv"),  emit: unzipped_archive

    script:
    """
    unzip ${file}
    """

}
