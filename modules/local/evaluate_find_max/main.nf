process EVALUATE_FIND_MAX {
    tag "${test_mode}_${model_name}_${split_id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/25/258ae8d4dc806d30de817bb11421fb2316bdb3dd3305dfaa37e5ea01eb475341/data' :
        'community.wave.seqera.io/library/python_pip_drevalpy:8252ebecce29d755' }"

    input:
    tuple val(model_name), val(test_mode), val(split_id), path(hpam_yamls), path(pred_datas)
    val metric

    output:
    tuple val(model_name), val(split_id), val(test_mode), path('best_hpam_combi_*.yaml'), emit: best_combis
    path("versions.yml"),                       emit: versions

    script:
    """
    drevalpy-evaluate-hpams \\
        --model_name "${model_name}" \\
        --split_id $split_id \\
        --hpam_yamls $hpam_yamls \\
        --pred_datas $pred_datas \\
        --optim_metric $metric

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(python -c "import drevalpy; print(drevalpy.__version__)")
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
        sklearn: \$(python -c "import sklearn; print(sklearn.__version__)")
        numpy: \$(python -c "import numpy; print(numpy.__version__)")
        scipy: \$(python -c "import scipy; print(scipy.__version__)")
        yaml: \$(python -c "import yaml; print(yaml.__version__)")
    END_VERSIONS
    """

}
