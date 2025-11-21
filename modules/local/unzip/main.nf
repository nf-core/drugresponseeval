process UNZIP {
    tag "${dataset_name}"
    label 'process_single'



    input:
    tuple val(dataset_name), path(file)

    output:
    tuple val(dataset_name), path("${file.baseName}/"),     emit: unzipped_archive
    path("${file.baseName}/${file.baseName}.csv"),          emit: unzipped_csv, optional: true
    path("versions.yml"),                                   emit: versions

    script:
    """
    unzip ${file}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        unzip: \$(unzip -v | sed -n 's/^UnZip \\([0-9.]\\+\\).*/\\1/p')
    END_VERSIONS
    """

}
