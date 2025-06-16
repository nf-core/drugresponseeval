#!/usr/bin/env python
import os
import pathlib
import argparse
import pandas as pd

from drevalpy.visualization.utils import create_output_directories, draw_test_mode_plots, draw_algorithm_plots, create_html, create_index_html


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

    for test_mode in test_modes:
        unique_algos = draw_test_mode_plots(
            test_mode=test_mode,
            ev_res=ev_res,
            ev_res_per_drug=ev_res_per_drug,
            ev_res_per_cell_line=ev_res_per_cl,
            custom_id=outdir_name,
            path_data=args.path_data,
            result_path=result_path,
        )
        # draw figures for each algorithm with all randomizations etc
        unique_algos = set(unique_algos) - {
            "NaiveMeanEffectsPredictor",
            "NaivePredictor",
            "NaiveCellLineMeansPredictor",
            "NaiveDrugMeanPredictor",
        }
        for algorithm in unique_algos:
            draw_algorithm_plots(
                model=algorithm,
                ev_res=ev_res,
                ev_res_per_drug=ev_res_per_drug,
                ev_res_per_cell_line=ev_res_per_cl,
                t_vs_p=t_vs_p,
                test_mode=test_mode,
                custom_id=outdir_name,
                result_path=result_path,
            )
        # get all html files from {result_path}/{run_id}
        all_files: list[str] = []
        for _, _, files in os.walk(f"{result_path}/{outdir_name}"):  # type: ignore[assignment]
            for file in files:
                if file.endswith("json") or (
                    file.endswith(".html") and file not in ["index.html", "LPO.html", "LCO.html", "LDO.html"]
                ):
                    all_files.append(file)
        # PIPELINE: WRITE_HTML
        create_html(
            run_id=outdir_name,
            test_mode=test_mode,
            files=all_files,
            prefix_results=f"{result_path}/{outdir_name}",
        )
    # PIPELINE: WRITE_INDEX
    create_index_html(
        custom_id=outdir_name,
        test_modes=test_modes,
        prefix_results=f"{result_path}/{outdir_name}",
    )
