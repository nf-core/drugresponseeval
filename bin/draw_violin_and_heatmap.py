#!/usr/bin/env python
import argparse
import pandas as pd

from drevalpy.visualization.violin import Violin
from drevalpy.visualization.heatmap import Heatmap


def get_parser():
    parser = argparse.ArgumentParser(description='Draw violin plots or heatmaps.')
    parser.add_argument('--plot', type=str, default='violinplot', help='Type of plot (violin or heatmap).')
    parser.add_argument('--name', type=str, required=True, help='Name/Setting of plot.')
    parser.add_argument('--data', type=str, required=True, help='Path to data.')
    return parser


def draw_violin_or_heatmap(plot_type: str, path_to_df: str, setting: str):
    df = pd.read_csv(path_to_df, index_col=0)
    if setting in ['LPO', 'LDO', 'LCO', 'LPO_normalized', 'LDO_normalized', 'LCO_normalized']:
        # subset df such that the column 'LPO_LCO_LDO' == setting and the column 'rand_setting' == 'predictions'
        df = df[(df['LPO_LCO_LDO'] == setting) & (df['rand_setting'] == 'predictions')]
        if setting in ['LPO', 'LDO', 'LCO']:
            if plot_type == 'violinplot':
                out_plot = Violin(df=df, normalized_metrics=False, whole_name=False)
            else:
                out_plot = Heatmap(df=df, normalized_metrics=False, whole_name=False)
        else:
            if plot_type == 'violinplot':
                out_plot = Violin(df=df, normalized_metrics=True, whole_name=False)
            else:
                out_plot = Heatmap(df=df, normalized_metrics=True, whole_name=False)
    else:
        name_split = setting.split('_')
        lpo_lco_ldo = name_split[0]
        algorithm = name_split[1]
        # subset df such that the column 'LPO_LCO_LDO' == lpo_lco_ldo and the column 'algorithm' == algorithm
        df = df[(df['LPO_LCO_LDO'] == lpo_lco_ldo) & (df['algorithm'] == algorithm)]
        if plot_type == 'violinplot':
            out_plot = Violin(df=df, normalized_metrics=False, whole_name=True)
        else:
            out_plot = Heatmap(df=df, normalized_metrics=False, whole_name=True)
    out_plot.fig.write_html(f'{plot_type}_{setting}.html')


if __name__ == "__main__":
    args = get_parser().parse_args()
    draw_violin_or_heatmap(args.plot, args.data, args.name)
