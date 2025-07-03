process RANDOMIZATION_SPLIT {
    tag "${model_name}_${randomization_mode}"
    label 'process_single'



    input:
    tuple val(model_name), val(randomization_mode)

    output:
    tuple val(model_name), path('randomization_test_view*.yaml'),     emit: randomization_test_views
    path("versions.yml"),                       emit: versions

    script:
    """
    randomization_split.py --model_name "${model_name}" --randomization_mode ${randomization_mode}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(python -c "import drevalpy; print(drevalpy.__version__)")
        sklearn: \$(python -c "import sklearn; print(sklearn.__version__)")
        numpy: \$(python -c "import numpy; print(numpy.__version__)")
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
        pytorch_lightning: \$(python -c "import pytorch_lightning; print(pytorch_lightning.__version__)")
        torch: \$(python -c "import torch; print(torch.__version__)")
        platform: \$(python -c "import platform; print(platform.__version__)")
        yaml: \$(python -c "import yaml; print(yaml.__version__)")
    END_VERSIONS
    """

}
