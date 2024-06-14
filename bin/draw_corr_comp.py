#!/usr/bin/env python
import argparse
import pandas as pd

from drevalpy.visualization.corr_comp_scatter import CorrelationComparisonScatter
from drevalpy.models import MODEL_FACTORY


def get_parser():
    parser = argparse.ArgumentParser(description='Draw violin plots.')
    parser.add_argument('--name', type=str, required=True, help='Name/Setting of plot.')
    parser.add_argument('--data', type=str, required=True, help='Path to data.')
    return parser


def draw_corr_comp(path_to_df: str, setting: str):
    df = pd.read_csv(path_to_df, index_col=0)
    # extract which lpo_ldo_lco setting is used
    lpo_lco_ldo = [name for name in ['LPO', 'LDO', 'LCO'] if name in setting][0]
    # if setting ends with _drug, set group_by to 'drug'
    group_by = 'drug' if setting.endswith('_drug') else 'cell_line'
    # if one of the names in model factory occurs in the setting, subset df accordingly
    if any(name in setting for name in MODEL_FACTORY):
        # get the name of the algorithm
        algorithm = setting.split('_')[0]
        # subset df such that the column 'algorithm' == algorithm
        df = df[(df['LPO_LCO_LDO'] == lpo_lco_ldo) & (df['algorithm'] == algorithm)]
        corr_comp = CorrelationComparisonScatter(df=df, color_by=group_by)
    else:
        # subset df such that the column 'LPO_LCO_LDO' == lpo_lco_ldo
        df = df[(df['LPO_LCO_LDO'] == lpo_lco_ldo) & (df['rand_setting'] == 'predictions')]
        corr_comp = CorrelationComparisonScatter(df=df, color_by=group_by)
    corr_comp.dropdown_fig.write_html(f'corr_comp_scatter_{setting}.html')
    corr_comp.fig_overall.write_html(f'corr_comp_scatter_overall_{setting}.html')


if __name__ == "__main__":
    args = get_parser().parse_args()
    draw_corr_comp(args.data, args.name)
