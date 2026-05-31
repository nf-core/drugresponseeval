process EVALUATE_FINAL {
    tag "${test_mode}_${model_name}_${pred_file}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/90/908156ca5b3770a1797cd6f564cea34935ab7b09b39643436494f3bdf6331266/data' :
        'community.wave.seqera.io/library/matplotlib_numpy_pandas_python_pruned:0868f8788117e11b' }"

    input:
    tuple val(test_mode), val(model_name), path(pred_file)

    output:
    path('*.csv'), emit: ch_individual_results, optional: true
    path("versions.yml"),                       emit: versions


    script:
    """
    drevalpy-evaluate-test \\
        --test_mode $test_mode \\
        --model_name "${model_name}" \\
        --pred_file $pred_file

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(python -c "import drevalpy; print(drevalpy.__version__)")
        pandas: \$(python -c "import pandas; print(pandas.__version__)")
        sklearn: \$(python -c "import sklearn; print(sklearn.__version__)")
        numpy: \$(python -c "import numpy; print(numpy.__version__)")
        scipy: \$(python -c "import scipy; print(scipy.__version__)")
    END_VERSIONS
    """

}
