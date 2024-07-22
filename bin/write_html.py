#!/usr/bin/env python
import argparse
from drevalpy.visualization.utils import create_html


def get_parser():
    parser = argparse.ArgumentParser(description="Write individual LCO/LDO/LPO html files.")
    parser.add_argument("--run_id", type=str, required=True, help="Run ID.")
    parser.add_argument("--test_mode", type=str, required=True, help="LPO, LDO, or LCO.")
    parser.add_argument("--files", type=str, nargs="+", required=True, help="Paths to files.")
    return parser


if __name__ == "__main__":
    args = get_parser().parse_args()
    create_html(run_id=args.run_id, lpo_lco_ldo=args.test_mode, files=args.files, prefix_results="")
