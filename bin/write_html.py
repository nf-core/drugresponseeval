#!/usr/bin/env python
import argparse
import shutil
import importlib.resources as pkg_resources

from drevalpy.visualization.utils import parse_layout, write_violins_and_heatmaps, write_scatter_eval_models


def get_parser():
    parser = argparse.ArgumentParser(description="Write individual LCO/LDO/LPO html files.")
    parser.add_argument("--run_id", type=str, required=True, help="Run ID.")
    parser.add_argument("--test_mode", type=str, required=True, help="LPO, LDO, or LCO.")
    parser.add_argument("--files", type=str, nargs="+", required=True, help="Paths to files.")
    return parser


def get_plot_list(files: list, lpo_lco_ldo: str, plot_type: str):
    return [
        f
        for f in files
        if lpo_lco_ldo in f
        and f.startswith(plot_type)
        and f != f"{plot_type}_{lpo_lco_ldo}.html"
        and f != f"{plot_type}_{lpo_lco_ldo}_normalized.html"
    ]


def write_table(f, table):
    with open(table, "r") as eval_f:
        eval_results = eval_f.readlines()
        eval_results[0] = eval_results[0].replace(
            '<table border="1" class="dataframe">',
            '<table class="display customDataTable" style="width:100%">',
        )
        for line in eval_results:
            f.write(line)


def write_html(run_id: str, lpo_lco_ldo: str, files: list):
    page_layout = str(pkg_resources.files("drevalpy").joinpath("visualization/style_utils/page_layout.html"))

    with open(f"{lpo_lco_ldo}.html", "w") as f:
        parse_layout(f=f, path_to_layout=page_layout)
        f.write(f"<h1>Results for {run_id}: {lpo_lco_ldo}</h1>\n")

        plot_list = get_plot_list(files=files, lpo_lco_ldo=lpo_lco_ldo, plot_type="violinplot")
        write_violins_and_heatmaps(f=f, setting=lpo_lco_ldo, plot_list=plot_list, plot="Violin")
        plot_list = get_plot_list(files=files, lpo_lco_ldo=lpo_lco_ldo, plot_type="heatmap")
        write_violins_and_heatmaps(f=f, setting=lpo_lco_ldo, plot_list=plot_list, plot="Heatmap")

        f.write('<h2 id="regression_plots">Regression plots</h2>\n')
        f.write("<ul>\n")
        regr_files = [f for f in files if lpo_lco_ldo in f and f.startswith("regression_lines")]
        for regr_file in regr_files:
            f.write(f'<li><a href="regression_plots/{regr_file}" target="_blanK">{regr_file}</a></li>\n')
        f.write("</ul>\n")

        f.write('<h2 id="corr_comp">Comparison of correlation metrics</h2>\n')
        corr_files = [
            f for f in files if lpo_lco_ldo in f and f.startswith("corr_comp_scatter") and f.endswith("drug.html")
        ]
        write_scatter_eval_models(f=f, setting=lpo_lco_ldo, group_by="drug", plot_list=corr_files)
        corr_files = [
            f for f in files if lpo_lco_ldo in f and f.startswith("corr_comp_scatter") and f.endswith("cell_line.html")
        ]
        write_scatter_eval_models(f=f, setting=lpo_lco_ldo, group_by="cell_line", plot_list=corr_files)

        f.write('<h2 id="tables"> Evaluation Results Table</h2>\n')
        whole_table = [f for f in files if f == f"table_{lpo_lco_ldo}.html"][0]
        write_table(f=f, table=whole_table)

        if lpo_lco_ldo != "LCO":
            f.write("<h2> Evaluation Results per Cell Line Table</h2>\n")
            cell_line_table = [f for f in files if f == f"table_{lpo_lco_ldo}_per_cl.html"][0]
            write_table(f=f, table=cell_line_table)

        if lpo_lco_ldo != "LDO":
            f.write("<h2> Evaluation Results per Drug Table</h2>\n")
            drug_table = [f for f in files if f == f"table_{lpo_lco_ldo}_per_drug.html"][0]
            write_table(f=f, table=drug_table)

        f.write("</div>\n")
        f.write("</body>\n")
        f.write("</html>\n")


if __name__ == "__main__":
    args = get_parser().parse_args()
    write_html(args.run_id, args.test_mode, args.files)
