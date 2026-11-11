process HPAM_SPLIT {
    tag "$model_name"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "matplotlib_numpy_pandas_python_pruned:4ca8e30ab27649ab"

    input:
    val model_name
    val no_hyperparameter_tuning

    output:
    tuple val(model_name), path("*.yaml")    , emit: hpam_combi
    tuple val("${task.process}"), val('python'), eval("python --version | sed 's/Python //g'"), topic: versions, emit: versions_python
    tuple val("${task.process}"), val('drevalpy'), eval("drevalpy --version | sed 's/drevalpy //'"), topic: versions, emit: versions_drevalpy
    tuple val("${task.process}"), val('yaml'), eval("python -c \"import yaml; print(yaml.__version__)\""), topic: versions, emit: versions_yaml


    script:
    """
    drevalpy make-hpam-yamls \\
        --model_name "${model_name}" \\
        ${no_hyperparameter_tuning ? '' : '--hyperparameter_tuning'}
    """

}
