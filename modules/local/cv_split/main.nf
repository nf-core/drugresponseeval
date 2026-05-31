process CV_SPLIT {
    tag "$test_mode"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/25/258ae8d4dc806d30de817bb11421fb2316bdb3dd3305dfaa37e5ea01eb475341/data' :
        'community.wave.seqera.io/library/python_pip_drevalpy:8252ebecce29d755' }"

    input:
    tuple val(test_mode), path(response)
    val n_cv_splits

    output:
    tuple val(test_mode), path("split*.pkl")    , emit: response_cv_splits
    path("versions.yml"),                       emit: versions


    script:
    """
    drevalpy-make-cv-pkls \\
        --response $response \\
        --n_cv_splits $n_cv_splits \\
        --test_mode $test_mode

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        drevalpy: \$(python -c "import drevalpy; print(drevalpy.__version__)")
        sklearn: \$(python -c "import sklearn; print(sklearn.__version__)")
        numpy: \$(python -c "import numpy; print(numpy.__version__)")
    END_VERSIONS
    """

}
