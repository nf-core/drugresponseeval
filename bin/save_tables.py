#!/usr/bin/env python
import argparse
import pandas as pd

from drevalpy.visualization import HTMLTable


def get_parser():
    parser = argparse.ArgumentParser(description="Save table as html.")
    parser.add_argument("--path_eval_results", type=str, required=True, help="Path to evaluation results.")
    parser.add_argument("--lpo_lco_ldo", type=str, required=True, help="LPO_LCO_LDO.")
    return parser


def main(path_eval_results: str, lpo_lco_ldo: str):
    df = pd.read_csv(path_eval_results)
    df = df[df["LPO_LCO_LDO"] == lpo_lco_ldo]

    if "per_drug" in path_eval_results:
        grouping = "drug"
        out_suffix = f"{grouping}_{lpo_lco_ldo}"
    elif "per_cl" in path_eval_results:
        grouping = "cell_line"
        out_suffix = f"{grouping}_{lpo_lco_ldo}"
    else:
        grouping = "all"
        out_suffix = lpo_lco_ldo

    html_table = HTMLTable(df=df,
                           group_by=grouping)
    html_table.draw_and_save(
        out_prefix="",
        out_suffix=out_suffix

    )


if __name__ == "__main__":
    args = get_parser().parse_args()
    main(args.path_eval_results, args.lpo_lco_ldo)
