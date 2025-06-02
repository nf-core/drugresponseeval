process UNZIP {
    tag "${dataset_name}"
    label 'process_single'

    input:
    tuple val(dataset_name), path(file)

    output:
    tuple val(dataset_name), path("${file.baseName}/"),  emit: unzipped_archive

    script:
    """
    unzip ${file}
    """

}
