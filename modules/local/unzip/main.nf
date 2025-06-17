process UNZIP {
    tag "${dataset_name}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"

    input:
    tuple val(dataset_name), path(file)

    output:
    tuple val(dataset_name), path("${file.baseName}/"), path("${file.baseName}/${file.baseName}.csv"),  emit: unzipped_archive
    path("versions.yml"),                       emit: versions

    script:
    """
    unzip ${file}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        unzip: 6.00
    END_VERSIONS
    """

}
