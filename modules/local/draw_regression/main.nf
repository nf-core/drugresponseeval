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
    from drevalpy.visualization.regression_slider_plot import RegressionSliderPlot

    name_split = '${name}'.split('_')
    lpo_lco_ldo = name_split[0]
    group_by = name_split[1]
    if group_by == 'cell':
        group_by = 'cell_line'
    normalized = '${name}'.endswith('normalized')
    true_vs_pred = pd.read_csv('${true_vs_pred}')
    true_vs_pred = true_vs_pred[(true_vs_pred['LPO_LCO_LDO'] == lpo_lco_ldo) & (true_vs_pred['algorithm'] == '${model}')]

    regr_slider = RegressionSliderPlot(
        df=true_vs_pred,
        group_by=group_by,
        normalize=normalized
    )
    regr_slider.fig.write_html('regression_lines_${name}_${model}.html')
    """

}
