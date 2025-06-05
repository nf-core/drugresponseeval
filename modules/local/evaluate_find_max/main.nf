process EVALUATE_FIND_MAX {
    tag "${test_mode}_${model_name}_${split_id}"
    label 'process_single'

    input:
    tuple val(model_name), val(test_mode), val(split_id), path(hpam_yamls), path(pred_datas)
    val metric

    output:
    tuple val(model_name), val(split_id), val(test_mode), path('best_hpam_combi_*.yaml'), emit: best_combis
    path("versions.yml"),                       emit: versions

    script:
    """
    evaluate_and_find_max.py \\
        --model_name "${model_name}" \\
        --split_id $split_id \\
        --hpam_yamls $hpam_yamls \\
        --pred_datas $pred_datas \\
        --metric $metric

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
