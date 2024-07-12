process DRAW_REGRESSION {
    tag "${name}_${model}"
    label 'process_single'
    publishDir "${params.outdir}/${params.run_id}/regression_plots"

    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"

    input:
    tuple val(name), val(model), path(true_vs_pred)

    output:
    path('regression_lines*.html'), emit: regression_lines

    script:
    """
    #!/usr/bin/env python
    import pandas as pd
    from drevalpy.visualization.utils import draw_regr_slider

    true_vs_pred = pd.read_csv('${true_vs_pred}', index_col=0)
    name_split = '${name}'.split('_')
    lpo_lco_ldo = name_split[0]
    group_by = name_split[1]
    if group_by == 'cell':
        group_by = 'cell_line'
    normalize = '${name}'.endswith('normalized')

    draw_regr_slider(
        t_v_p=true_vs_pred,
        lpo_lco_ldo=lpo_lco_ldo,
        model='${model}',
        grouping_slider=group_by,
        out_prefix='',
        name='${name}',
        normalize=normalize
    )
    """

}
