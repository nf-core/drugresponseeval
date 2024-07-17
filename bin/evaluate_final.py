#!/usr/bin/env python
import os
import argparse
import pandas as pd

from drevalpy.datasets.dataset import DrugResponseDataset
from drevalpy.evaluation import evaluate, AVAILABLE_METRICS
from drevalpy.visualization.utils import evaluate_per_group


def get_parser():
    parser = argparse.ArgumentParser(description="Evaluate the predictions from the final model.")
    parser.add_argument("--test_mode", type=str, default="LPO", help="Test mode (LPO, LCO, LDO).")
    parser.add_argument("--model_name", type=str, required=True, help="Model name.")
    parser.add_argument("--pred_file", type=str, required=True, help="Path to predictions.")
    return parser


def generate_name(test_mode, model_name, pred_file):
    pred_rand_rob = os.path.basename(pred_file).split("_")[0]
    if pred_rand_rob == "predictions":
        pred_setting = "predictions"
    elif pred_rand_rob == "randomization":
        pred_setting = "randomize-" + "-".join(os.path.basename(pred_file).split("_")[1:-2])
    else:
        pred_setting = "-".join(os.path.basename(pred_file).split("_")[:2])
    split = "_".join(os.path.basename(pred_file).split(".")[0].split("_")[-2:])
    return f"{model_name}_{pred_setting}_{test_mode}_{split}"


def evaluate_file(test_mode, model_name, pred_file):
    print("Parsing file:", os.path.normpath(pred_file))
    result = pd.read_csv(pred_file)
    dataset = DrugResponseDataset(
        response=result["response"],
        cell_line_ids=result["cell_line_ids"],
        drug_ids=result["drug_ids"],
        predictions=result["predictions"],
    )
    model = generate_name(test_mode, model_name, pred_file)
    overall_eval = {model: evaluate(dataset, AVAILABLE_METRICS.keys())}
    true_vs_pred = pd.DataFrame(
        {
            "model": [model for _ in range(len(dataset.response))],
            "drug": dataset.drug_ids,
            "cell_line": dataset.cell_line_ids,
            "y_true": dataset.response,
            "y_pred": dataset.predictions,
        }
    )

    evaluation_results_per_drug = None
    evaluation_results_per_cl = None
    norm_drug_eval_results = {}
    norm_cl_eval_results = {}
    if "LPO" == test_mode or "LCO" == test_mode:
        norm_drug_eval_results, evaluation_results_per_drug = evaluate_per_group(
            df=true_vs_pred,
            group_by="drug",
            norm_group_eval_results=norm_drug_eval_results,
            eval_results_per_group=evaluation_results_per_drug,
            model=model,
        )
    if "LPO" == test_mode or "LDO" == test_mode:
        norm_cl_eval_results, evaluation_results_per_cl = evaluate_per_group(
            df=true_vs_pred,
            group_by="cell_line",
            norm_group_eval_results=norm_cl_eval_results,
            eval_results_per_group=evaluation_results_per_cl,
            model=model,
        )
    overall_eval = pd.DataFrame.from_dict(overall_eval, orient="index")
    if norm_drug_eval_results != {}:
        overall_eval = concat_results(norm_drug_eval_results, "drug", overall_eval)
    if norm_cl_eval_results != {}:
        overall_eval = concat_results(norm_cl_eval_results, "cell_line", overall_eval)

    return overall_eval, evaluation_results_per_drug, evaluation_results_per_cl, true_vs_pred, model


def write_results(overall_eval, evaluation_results_per_drug, evaluation_results_per_cl, true_vs_pred, model_name):
    overall_eval.to_csv(f"{model_name}_evaluation_results.csv")
    if evaluation_results_per_drug is not None:
        evaluation_results_per_drug.to_csv(f"{model_name}_evaluation_results_per_drug.csv")
    if evaluation_results_per_cl is not None:
        evaluation_results_per_cl.to_csv(f"{model_name}_evaluation_results_per_cl.csv")
    true_vs_pred.to_csv(f"{model_name}_true_vs_pred.csv")


def concat_results(norm_group_res, group_by, eval_res):
    norm_group_res = pd.DataFrame.from_dict(norm_group_res, orient="index")
    # append 'group normalized ' to the column names
    norm_group_res.columns = [f"{col}: {group_by} normalized" for col in norm_group_res.columns]
    eval_res = pd.concat([eval_res, norm_group_res], axis=1)
    return eval_res


if __name__ == "__main__":
    args = get_parser().parse_args()
    results_all, eval_res_d, eval_res_cl, t_vs_pred, mname = evaluate_file(
        args.test_mode, args.model_name, args.pred_file
    )
    write_results(results_all, eval_res_d, eval_res_cl, t_vs_pred, mname)
