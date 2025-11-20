#!/usr/bin/env python

# Written by Judith Bernett and released under the MIT License.

import argparse
import pickle
import yaml

from drevalpy.evaluation import evaluate, MAXIMIZATION_METRICS, MINIMIZATION_METRICS


def get_parser():
    parser = argparse.ArgumentParser(
        description="Take model name, get hyperparameters, and split into single hyperparameter combinations"
    )
    parser.add_argument("--model_name", type=str, help="model name")
    parser.add_argument("--split_id", type=str, help="split id")
    parser.add_argument("--hpam_yamls", nargs="+", help="paths to hpam yamls")
    parser.add_argument("--pred_datas", nargs="+", help="paths to pred datas")
    parser.add_argument("--metric", type=str, help="metric")
    return parser


def best_metric(metric, current_metric, best_metric):
    if metric in MINIMIZATION_METRICS:
        if current_metric < best_metric:
            return True
    elif metric in MAXIMIZATION_METRICS:
        if current_metric > best_metric:
            return True
    else:
        raise ValueError(f"Metric {metric} not recognized.")
    return False


if __name__ == "__main__":
    parser = get_parser()
    args = parser.parse_args()
    hpam_yamls = []
    for hpam_yaml in args.hpam_yamls:
        hpam_yamls.append(hpam_yaml)
    pred_datas = []
    for pred_data in args.pred_datas:
        pred_datas.append(pred_data)

    best_hpam_combi = None
    best_result = None
    for i in range(0, len(pred_datas)):
        pred_data = pickle.load(open(pred_datas[i], "rb"))
        with open(hpam_yamls[i], "r") as yaml_file:
            hpam_combi = yaml.load(yaml_file, Loader=yaml.FullLoader)
        results = evaluate(pred_data, args.metric)
        if best_result is None:
            best_result = results[args.metric]
            best_hpam_combi = hpam_combi
        elif best_metric(args.metric, results[args.metric], best_result):
            best_result = results[args.metric]
            best_hpam_combi = hpam_combi
    final_result = {
        f"{args.model_name}_{args.split_id}": {"best_hpam_combi": best_hpam_combi, "best_result": best_result}
    }
    with open(f"best_hpam_combi_{args.split_id}.yaml", "w") as yaml_file:
        yaml.dump(final_result, yaml_file, default_flow_style=False)
