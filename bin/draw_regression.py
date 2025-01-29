#!/usr/bin/env python
import argparse
import pandas as pd

from drevalpy.visualization.regression_slider_plot import RegressionSliderPlot


def get_parser():
    parser = argparse.ArgumentParser(description="Draw regression plot.")
    parser.add_argument("--path_t_vs_p", type=str, required=True, help="Path to true_vs_pred.csv.")
    parser.add_argument("--name", type=str, required=True, help="Setting name.")
    parser.add_argument("--model", type=str, required=True, help="Model name.")
    return parser


def main(path_to_true_vs_pred: str, name: str, model: str):
    true_vs_pred = pd.read_csv(path_to_true_vs_pred, index_col=0)

    name_split = name.split("_")
    lpo_lco_ldo = name_split[0]
    group_by = name_split[1]
    if group_by == "cell":
        group_by = "cell_line"
    normalize = name.endswith("normalized")

    regr_slider = RegressionSliderPlot(
        df=true_vs_pred,
        lpo_lco_ldo=lpo_lco_ldo,
        model=model,
        group_by=group_by,
        normalize=normalize,
    )
    regr_slider.draw_and_save(out_prefix="", out_suffix=f"{name}_{model}")


if __name__ == "__main__":
    args = get_parser().parse_args()
    main(args.path_t_vs_p, args.name, args.model)
