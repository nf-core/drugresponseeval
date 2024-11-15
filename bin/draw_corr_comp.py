#!/usr/bin/env python
import argparse
import pandas as pd

from drevalpy.visualization.utils import CorrelationComparisonScatter
from drevalpy.models import MODEL_FACTORY


def get_parser():
    parser = argparse.ArgumentParser(description="Draw violin plots.")
    parser.add_argument("--name", type=str, required=True, help="Name/Setting of plot.")
    parser.add_argument("--data", type=str, required=True, help="Path to data.")
    return parser


def draw_corr_comp(path_to_df: str, setting: str):
    df = pd.read_csv(path_to_df, index_col=0)
    group_by = "drug" if setting.endswith("_drug") else "cell_line"
    lpo_lco_ldo = [name for name in ["LPO", "LDO", "LCO"] if name in setting][0]
    if any(name in setting for name in MODEL_FACTORY):
        algorithm = setting.split("_")[0]
    else:
        algorithm = "all"
    corr_comp = CorrelationComparisonScatter(df=df, color_by=group_by, lpo_lco_ldo=lpo_lco_ldo, algorithm=algorithm)
    if corr_comp.name is not None:
        corr_comp.draw_and_save(out_prefix="", out_suffix=corr_comp.name)


if __name__ == "__main__":
    args = get_parser().parse_args()
    draw_corr_comp(path_to_df=args.data, setting=args.name)
