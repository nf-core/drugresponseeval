include { VISUALIZE_RESULTS               } from '../../../modules/local/visualize_results'


workflow VISUALIZATION {
    take:
    evaluation_results                  // from MODEL_TESTING
    evaluation_results_per_drug         // from MODEL_TESTING
    evaluation_results_per_cl           // from MODEL_TESTING
    true_vs_pred                        // from MODEL_TESTING
    work_path                           // from input

    main:
    ch_input_vis = evaluation_results.concat(
        evaluation_results_per_drug,
        evaluation_results_per_cl,
        true_vs_pred
    ).collect()

    VISUALIZE_RESULTS(
        ch_input_vis,
        work_path
    )

}
