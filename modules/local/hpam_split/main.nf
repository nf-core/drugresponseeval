process HPAM_SPLIT {
    tag "$model_name"
    label 'process_single'

    input:
    val model_name

    output:
    tuple val(model_name), path("*.yaml")    , emit: hpam_combi


    script:
    """
    hpam_split.py \\
        --model_name "${model_name}"
    """

}
