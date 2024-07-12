process SAVE_TABLES {
    tag "${lpo_lco_ldo}_${eval_results}"
    label 'process_single'
    publishDir "${params.outdir}/${params.run_id}/html_tables"

    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"

    input:
    tuple val(lpo_lco_ldo), path(eval_results)

    output:
    path('table*.html'), emit: html_table

    script:
    """
    #!/usr/bin/env python
    import pandas as pd
    from drevalpy.visualization.utils import export_setting_html_table

    df = pd.read_csv('${eval_results}')
    df = df[df['LPO_LCO_LDO'] == '${lpo_lco_ldo}']

    if 'per_drug' in '${eval_results}':
        grouping = 'drug'
    elif 'per_cl' in '${eval_results}':
        grouping = 'cell_line'
    else:
        grouping = 'all'

    export_path = f'table_{grouping}_${lpo_lco_ldo}.html'
    export_setting_html_table(df=df, export_path=export_path, grouping=grouping)
    """

}
