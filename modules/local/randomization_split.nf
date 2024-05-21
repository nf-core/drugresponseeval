process RANDOMIZATION_SPLIT {
    tag "${model_name}_${randomization_mode}"
    label 'process_single'

    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"
    input:
    tuple val(model_name), val(randomization_mode)

    output:
    tuple val(model_name), path('randomization_test_view*.yaml'),     emit: randomization_test_views

    script:
    """
    #!/usr/bin/env python
    import pickle
    import yaml
    from dreval.models import MODEL_FACTORY
    from dreval.experiment import get_randomization_test_views

    model_class = MODEL_FACTORY['${model_name}']
    model = model_class(target='IC50')

    randomization_test_views = get_randomization_test_views(
                                    model=model,
                                    randomization_mode=['${randomization_mode}']
                               )

    key = list(randomization_test_views.keys())[0]
    # create as many dicts as there are elements in the value list of the key
    randomization_test_view_dicts = [{'test_name': key, 'view': value} for value in randomization_test_views[key]]

    for rand_dict in randomization_test_view_dicts:
        with open(f'randomization_test_view_{rand_dict["test_name"]}.yaml', 'w') as f:
            yaml.dump(rand_dict, f)
    """

}
