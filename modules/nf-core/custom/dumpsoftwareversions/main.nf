process CUSTOM_DUMPSOFTWAREVERSIONS {
    label 'process_single'

    // Requires `pyyaml` which does not have a dedicated container but is in the MultiQC container
    conda "${moduleDir}/environment.yml"
    container "multiqc:1.27--b0d1ffb40dfd9e97"

    input:
    path versions

    output:
    path "software_versions.yml"    , emit: yml
    path "software_versions_mqc.yml", emit: mqc_yml
    path "versions.yml"             , emit: versions, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def deprecation_message = """
WARNING: This module has been deprecated.

Reason:
This module is no longer recommended for use, as it is replaced by the function softwareVersionsToYAML
in the utils_nfcore_pipeline subworkflow that is included in the nf-core template.

"""
    assert false: deprecation_message
    template 'dumpsoftwareversions.py'
}
