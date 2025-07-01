#!/usr/bin/env python

# Written by Judith Bernett and released under the MIT License.

import pathlib
import argparse
import pandas as pd

from drevalpy.visualization.utils import create_output_directories, create_index_html
from drevalpy.visualization.create_report import generate_reports_for_all_test_modes


def get_parser():
    parser = argparse.ArgumentParser(description="Write individual LCO/LTO/LDO/LPO html files.")
    parser.add_argument("--test_modes", type=str, nargs="+", required=True, help="LPO, LDO, LCO, or LTO.")
    parser.add_argument("--eval_results", type=str, required=True, help="Path to the evaluation results.")
    parser.add_argument("--eval_results_per_drug", type=str, required=True, help="Path to the evaluation results per drug.")
    parser.add_argument("--eval_results_per_cl", type=str, required=True, help="Path to the evaluation results per cell line.")
    parser.add_argument("--true_vs_predicted", type=str, required=True, help="Path to the true vs predicted results.")
    parser.add_argument("--path_data", type=str, required=True, help="Path to the data.")
    return parser


if __name__ == "__main__":
    args = get_parser().parse_args()
    result_path = pathlib.Path(".")
    outdir_name = "report"
    create_output_directories(result_path=result_path, custom_id=outdir_name)
    test_modes = args.test_modes

    ev_res = pd.read_csv(args.eval_results, index_col=0)
    if args.eval_results_per_drug == "NO_FILE":
        ev_res_per_drug = None
    else:
        ev_res_per_drug = pd.read_csv(args.eval_results_per_drug, index_col=0)
    if args.eval_results_per_cl == "NO_FILE":
        ev_res_per_cl = None
    else:
        ev_res_per_cl = pd.read_csv(args.eval_results_per_cl, index_col=0)
    t_vs_p = pd.read_csv(args.true_vs_predicted, index_col=0)

    generate_reports_for_all_test_modes(
        test_modes=test_modes,
        evaluation_results=ev_res,
        evaluation_results_per_drug=ev_res_per_drug,
        evaluation_results_per_cell_line=ev_res_per_cl,
        true_vs_pred=t_vs_p,
        run_id=outdir_name,
        path_data=args.path_data,
        result_path=result_path
    )

    create_index_html(
        custom_id=outdir_name,
        test_modes=test_modes,
        prefix_results=f"{result_path}/{outdir_name}",
    )
