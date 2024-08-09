#!/usr/bin/env python
import argparse

from drevalpy.visualization.utils import evaluate_file


def get_parser():
    parser = argparse.ArgumentParser(description="Evaluate the predictions from the final model.")
    parser.add_argument("--test_mode", type=str, default="LPO", help="Test mode (LPO, LCO, LDO).")
    parser.add_argument("--model_name", type=str, required=True, help="Model name.")
    parser.add_argument("--pred_file", type=str, required=True, help="Path to predictions.")
    return parser


def write_results(overall_eval, evaluation_results_per_drug, evaluation_results_per_cl, true_vs_pred, model_name):
    overall_eval.to_csv(f"{model_name}_evaluation_results.csv")
    if evaluation_results_per_drug is not None:
        evaluation_results_per_drug.to_csv(f"{model_name}_evaluation_results_per_drug.csv")
    if evaluation_results_per_cl is not None:
        evaluation_results_per_cl.to_csv(f"{model_name}_evaluation_results_per_cl.csv")
    true_vs_pred.to_csv(f"{model_name}_true_vs_pred.csv")


if __name__ == "__main__":
    args = get_parser().parse_args()
    results_all, eval_res_d, eval_res_cl, t_vs_pred, mname = evaluate_file(
        test_mode=args.test_mode, model_name=args.model_name, pred_file=args.pred_file
    )
    write_results(results_all, eval_res_d, eval_res_cl, t_vs_pred, mname)
