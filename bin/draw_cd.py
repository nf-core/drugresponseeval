#!/usr/bin/env python
import argparse
import pandas as pd

from drevalpy.visualization.critical_difference_plot import CriticalDifferencePlot

def get_parser():
    parser = argparse.ArgumentParser(description="Draw critical difference plots.")
    parser.add_argument("--name", type=str, required=True, help="Name/Setting of plot.")
    parser.add_argument("--data", type=str, required=True, help="Path to data.")
    return parser


def draw_cd(path_to_df: str, setting: str):
    df = pd.read_csv(path_to_df, index_col=0)
    df = df[(df["LPO_LCO_LDO"] == setting) & (df["rand_setting"] == "predictions")]
    cd_plot = CriticalDifferencePlot(
        eval_results_preds=df,
        metric='MSE'
    )
    cd_plot.draw_and_save(
        out_prefix='',
        out_suffix=setting
    )


if __name__ == "__main__":
    args = get_parser().parse_args()
    draw_cd(path_to_df=args.data, setting=args.name)
