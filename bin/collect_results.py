#!/usr/bin/env python
import argparse
import pandas as pd


def get_parser():
    parser = argparse.ArgumentParser(description='Collect results and write to single files.')
    parser.add_argument('--outfiles', type=str, nargs='+', required=True, help='Output files.')
    return parser


def collapse_file(files):
    out_df = None
    for file in files:
        if out_df is None:
            out_df = pd.read_csv(file, index_col=0)
        else:
            out_df = pd.concat([out_df, pd.read_csv(file, index_col=0)])
    return out_df


if __name__ == "__main__":
    args = get_parser().parse_args()
    # get all files with the pattern f'{model_name}_evaluation_results.csv' from args.outfiles
    eval_result_files = [file for file in args.outfiles if 'evaluation_results.csv' in file]
    # get all files with the pattern f'{model_name}_evaluation_results_per_drug.csv' from args.outfiles
    eval_result_per_drug_files = [file for file in args.outfiles if 'evaluation_results_per_drug.csv' in file]
    # get all files with the pattern f'{model_name}_evaluation_results_per_cl.csv' from args.outfiles
    eval_result_per_cl_files = [file for file in args.outfiles if 'evaluation_results_per_cl.csv' in file]
    # get all files with the pattern f'{model_name}_true_vs_pred.csv' from args.outfiles
    true_vs_pred_files = [file for file in args.outfiles if 'true_vs_pred.csv' in file]

    eval_results = collapse_file(eval_result_files)
    eval_results_per_drug = collapse_file(eval_result_per_drug_files)
    eval_results_per_cell_line = collapse_file(eval_result_per_cl_files)
    t_vs_p = collapse_file(true_vs_pred_files)

    new_columns = eval_results.index.str.split('_', expand=True).to_frame()
    new_columns.columns = ['algorithm', 'rand_setting', 'LPO_LCO_LDO', 'split', 'CV_split']
    new_columns.index = eval_results.index
    eval_results = pd.concat([new_columns.drop('split', axis=1), eval_results], axis=1)
    eval_results_per_drug[['algorithm', 'rand_setting', 'LPO_LCO_LDO', 'split', 'CV_split']] = eval_results_per_drug[
        'model'].str.split(
        '_', expand=True)
    eval_results_per_cell_line[['algorithm', 'rand_setting', 'LPO_LCO_LDO', 'split', 'CV_split']] = \
        eval_results_per_cell_line['model'].str.split(
            '_', expand=True)
    t_vs_p[['algorithm', 'rand_setting', 'LPO_LCO_LDO', 'split', 'CV_split']] = t_vs_p['model'].str.split(
        '_', expand=True)

    eval_results.to_csv('evaluation_results.csv', index=True)
    eval_results_per_drug.to_csv('evaluation_results_per_drug.csv', index=True)
    eval_results_per_cell_line.to_csv('evaluation_results_per_cl.csv', index=True)
    t_vs_p.to_csv('true_vs_pred.csv', index=True)
