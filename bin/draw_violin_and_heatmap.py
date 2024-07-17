#!/usr/bin/env python
import argparse
import pandas as pd

from drevalpy.visualization.utils import draw_violin_or_heatmap


def get_parser():
    parser = argparse.ArgumentParser(description="Draw violin plots or heatmaps.")
    parser.add_argument("--plot", type=str, default="violinplot", help="Type of plot (violin or heatmap).")
    parser.add_argument("--name", type=str, required=True, help="Name/Setting of plot.")
    parser.add_argument("--data", type=str, required=True, help="Path to data.")
    return parser


def prep_df(plot_type: str, path_to_df: str, setting: str):
    df = pd.read_csv(path_to_df, index_col=0)
    if setting in ["LPO", "LDO", "LCO", "LPO_normalized", "LDO_normalized", "LCO_normalized"]:
        # overview plots
        if setting in ["LPO", "LDO", "LCO"]:
            # overview for setting, only 'rand_setting' == 'predictions'
            df = df[(df["LPO_LCO_LDO"] == setting) & (df["rand_setting"] == "predictions")]
            out_plot = draw_violin_or_heatmap(plot_type, df, normalized_metrics=False, whole_name=False)
        else:
            # overview for normalized setting, only 'rand_setting' == 'predictions'
            lpo_lco_ldo = setting.split("_")[0]
            df = df[(df["LPO_LCO_LDO"] == lpo_lco_ldo) & (df["rand_setting"] == "predictions")]
            out_plot = draw_violin_or_heatmap(plot_type, df, normalized_metrics=True, whole_name=False)
    else:
        # algorithm-wise plots
        name_split = setting.split("_")
        lpo_lco_ldo = name_split[0]
        algorithm = name_split[1]
        df = df[(df["LPO_LCO_LDO"] == lpo_lco_ldo) & (df["algorithm"] == algorithm)]
        out_plot = draw_violin_or_heatmap(plot_type, df, normalized_metrics=False, whole_name=True)
    out_plot.fig.write_html(f"{plot_type}_{setting}.html")


if __name__ == "__main__":
    args = get_parser().parse_args()
    prep_df(args.plot, args.data, args.name)
