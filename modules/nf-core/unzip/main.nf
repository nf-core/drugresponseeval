process UNZIP {
    tag "$archive"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "p7zip:16.02--94efedc6cfea7db9"

    input:
    tuple val(meta), path(archive)

    output:
    tuple val(meta), path("${prefix}/"), emit: unzipped_archive
    path("${prefix}/${prefix}.csv")    , emit: unzipped_csv, optional: true
    tuple val("${task.process}"), val('7za'), eval("7za 2>&1 | sed -n '2s/^.* \\([0-9.]*\\) .*/\\1/p'"), topic: versions, emit: versions_7za

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    if ( archive instanceof List && archive.name.size > 1 ) { error "[UNZIP] error: 7za only accepts a single archive as input. Please check module input." }
    prefix = task.ext.prefix ?: ( meta.id ? "${meta.id}" : archive.baseName)
    """
    7za \\
        x \\
        $args \\
        $archive
    """

    stub:
    if ( archive instanceof List && archive.name.size > 1 ) { error "[UNZIP] error: 7za only accepts a single archive as input. Please check module input." }
    prefix = task.ext.prefix ?: ( meta.id ? "${meta.id}" : archive.baseName)
    """
    mkdir "${prefix}"
    """
}
