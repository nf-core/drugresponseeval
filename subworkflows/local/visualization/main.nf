include { DRAW_CRITICAL_DIFFERENCE  } from '../../../modules/local/draw_critical_difference'
include { DRAW_VIOLIN               } from '../../../modules/local/draw_violin'
include { DRAW_HEATMAP              } from '../../../modules/local/draw_heatmap'
include { DRAW_CORR_COMP            } from '../../../modules/local/draw_corr_comp'
include { DRAW_REGRESSION           } from '../../../modules/local/draw_regression'
include { SAVE_TABLES               } from '../../../modules/local/save_tables'
include { WRITE_HTML                } from '../../../modules/local/write_html'
include { WRITE_INDEX               } from '../../../modules/local/write_index'


workflow VISUALIZATION {
    take:
    test_modes                          // from input
    models                              // from input
    baselines                           // from input
    evaluation_results                  // from MODEL_TESTING
    evaluation_results_per_drug         // from MODEL_TESTING
    evaluation_results_per_cl           // from MODEL_TESTING
    true_vs_pred                        // from MODEL_TESTING

    main:
    ch_test_modes = channel.from(test_modes)
    ch_test_modes_normalized = ch_test_modes.map { it + "_normalized" }

    ch_models = channel.from(models)
    ch_baselines = channel.from(baselines)
    ch_models_baselines = ch_models.concat(ch_baselines)

    ch_combined = ch_test_modes.combine(ch_models_baselines)
    ch_combined_mapped = ch_combined.map { it[0] + "_" + it[1] }

    ch_cd = ch_test_modes.combine(evaluation_results)
    DRAW_CRITICAL_DIFFERENCE(
        ch_cd
    )

    ch_vio_heat = ch_test_modes.concat(ch_test_modes_normalized).concat(ch_combined_mapped)

    DRAW_VIOLIN (
        ch_vio_heat,
        evaluation_results
    )

    DRAW_HEATMAP (
        ch_vio_heat,
        evaluation_results
    )

    def suffixes = ['LCO': '_drug',
                'LDO': '_cell_line',
                'LPO': ['_drug', '_cell_line']]

    ch_test_modes_extended = ch_test_modes.flatMap { test_mode ->
        def modeSuffixes = suffixes[test_mode]
        if (modeSuffixes instanceof String) {
            return [test_mode + modeSuffixes]
        } else {
            return modeSuffixes.collect { test_mode + it }
        }
    }

    ch_modes_algos = ch_test_modes_extended.combine(ch_models_baselines)
    ch_modes_algos = ch_modes_algos.map { it[1] + "_" + it[0] }
    ch_test_modes_extended = ch_test_modes_extended.concat(ch_modes_algos)

    ch_test_modes_extended_drug = ch_test_modes_extended.filter { it.endsWith("_drug") }
    ch_test_modes_extended_cl = ch_test_modes_extended.filter { it.endsWith("_cell_line") }

    ch_test_modes_extended_drug = ch_test_modes_extended_drug.combine(evaluation_results_per_drug)
    ch_test_modes_extended_cl = ch_test_modes_extended_cl.combine(evaluation_results_per_cl)

    ch_test_modes_extended = ch_test_modes_extended_drug.concat(ch_test_modes_extended_cl)

    DRAW_CORR_COMP (
        ch_test_modes_extended
    )

    def suffixes_regr = ['LCO': ['_cell_line', '_cell_line_normalized'],
                'LDO': ['_drug', '_drug_normalized'],
                'LPO': ['_drug', '_drug_normalized', '_cell_line', '_cell_line_normalized']]

    ch_regr = ch_test_modes.flatMap { test_mode ->
        def modeSuffixes = suffixes_regr[test_mode]
        return modeSuffixes.collect { test_mode + it }
    }
    ch_regr = ch_regr.combine(ch_models_baselines).combine(true_vs_pred)

    DRAW_REGRESSION (
        ch_regr
    )

    ch_drug = ch_test_modes.filter { it == 'LCO' || it == 'LPO' }
    ch_drug = ch_drug.combine(evaluation_results_per_drug)
    ch_cl = ch_test_modes.filter { it == 'LDO' || it == 'LPO' }
    ch_cl = ch_cl.combine(evaluation_results_per_cl)

    ch_tables = ch_test_modes.combine(evaluation_results)
    ch_tables = ch_tables.concat(ch_drug).concat(ch_cl)

    SAVE_TABLES (
        ch_tables
    )

    ch_html_files = DRAW_CRITICAL_DIFFERENCE.out.critical_difference
                    .concat(DRAW_VIOLIN.out.violin_plot)
                    .concat(DRAW_HEATMAP.out.heatmap)
                    .concat(DRAW_CORR_COMP.out.corr_comp_scatter)
                    .concat(DRAW_REGRESSION.out.regression_lines)
                    .concat(SAVE_TABLES.out.html_table)
                    .flatten()
    ch_lpo = ch_html_files
            .filter { it.baseName.contains('LPO') }
            .map { it -> ['LPO', it] }
    ch_lco = ch_html_files
            .filter { it.baseName.contains('LCO') }
            .map { it -> ['LCO', it] }
    ch_ldo = ch_html_files
            .filter { it.baseName.contains('LDO') }
            .map { it -> ['LDO', it] }
    ch_html_files = ch_lpo.concat(ch_lco).concat(ch_ldo).groupTuple(by: 0)

    WRITE_HTML (
        params.run_id,
        ch_html_files
    )

    WRITE_INDEX (
        params.run_id,
        params.test_mode,
        WRITE_HTML.out.html_out.count()
    )

}
