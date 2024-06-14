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

    df = pd.read_csv('${eval_results}')
    df = df[df['LPO_LCO_LDO'] == '${lpo_lco_ldo}']

    selected_columns = [
        "algorithm",
        "rand_setting",
        "CV_split",
        "MSE",
        "R^2",
        "Pearson",
        "RMSE",
        "MAE",
        "Spearman",
        "Kendall",
        "Partial_Correlation",
        "LPO_LCO_LDO"
    ]

    if 'per_drug' in '${eval_results}':
        extra = '_per_drug'
        selected_columns = ['drug'] + selected_columns
    elif 'per_cl' in '${eval_results}':
        extra = '_per_cl'
        selected_columns = ['cell_line'] + selected_columns
    else:
        extra = ''
        selected_columns = [
            "algorithm",
            "rand_setting",
            "CV_split",
            "MSE",
            "R^2",
            "Pearson",
            "R^2: drug normalized",
            "Pearson: drug normalized",
            "R^2: cell_line normalized",
            "Pearson: cell_line normalized",
            "RMSE",
            "MAE",
            "Spearman",
            "Kendall",
            "Partial_Correlation",
            "Spearman: drug normalized",
            "Kendall: drug normalized",
            "Partial_Correlation: drug normalized",
            "Spearman: cell_line normalized",
            "Kendall: cell_line normalized",
            "Partial_Correlation: cell_line normalized",
            "LPO_LCO_LDO"
        ]
    df = df[selected_columns]
    df.to_html(f'table_${lpo_lco_ldo}{extra}.html', index=False)
    """

}
