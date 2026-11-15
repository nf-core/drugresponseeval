include { LOAD } from '../../../modules/local/load/main.nf'
include { SPLIT } from '../../../modules/local/split/main.nf'
include { DESCRIBE } from '../../../modules/local/describe/main.nf'
include { SINGLE as SINGLE_GPU } from '../../../modules/local/single/main.nf'
include { SINGLE as SINGLE_CPU } from '../../../modules/local/single/main.nf'
include { AGGREGATE } from '../../../modules/local/aggregate/main.nf'
include { REPORT } from '../../../modules/local/report/main.nf'

workflow RUN {

    take:
    models                    // channel: model name/recipe strings
    normalization_reference   // val: baseline model name for REPORT
    dataset_file
    dataset_name
    test_mode
    n_cv_splits
    measure
    no_hyperparameter_tuning
    optim_metric
    hpo_num_samples
    response_transformation


    main:

    if (!dataset_file) {
        LOAD (
            dataset_name
        )
        ch_dataset = LOAD.out.data.collect()
    } else {
        ch_dataset = channel.value(file(dataset_file, checkIfExists: true))
    }

    SPLIT (
        ch_dataset,
        test_mode,
        n_cv_splits,
        measure
    )

    //
    // Route every model by the accelerator level drevalpy declares for it:
    // 'optional' and 'required' models train in SINGLE_GPU, 'none' models in SINGLE_CPU.
    //
    ch_model_list = models.collect()

    DESCRIBE (
        ch_model_list
    )

    def gpu_profile = workflow.profile.contains('gpu')

    ch_routed = DESCRIBE.out.tsv
        .combine(ch_model_list.map { model_list -> [model_list] })
        .flatMap { tsv, model_list ->
            def rows = tsv.splitCsv(sep: '\t', header: true)
            def described = rows.collect { row -> row.model } as Set
            def mismatched = ((model_list as Set) - described) + (described - (model_list as Set))
            if (mismatched) {
                error("drevalpy describe returned model names that differ from the samplesheet: ${mismatched.sort().join(', ')}")
            }
            rows.collect { row ->
                if (row.accelerator == 'required' && !gpu_profile) {
                    error("Model '${row.model}' requires a GPU accelerator; run with -profile gpu.")
                }
                [row.model, row.accelerator]
            }
        }
        .branch { model, accelerator ->
            gpu: accelerator in ['optional', 'required']
                return model
            cpu: true
                return model
        }

    ch_folds = SPLIT.out.folds.flatten()

    SINGLE_GPU (
        ch_routed.gpu.combine(ch_folds),
        ch_dataset,
        no_hyperparameter_tuning,
        optim_metric,
        hpo_num_samples,
        response_transformation
    )

    SINGLE_CPU (
        ch_routed.cpu.combine(ch_folds),
        ch_dataset,
        no_hyperparameter_tuning,
        optim_metric,
        hpo_num_samples,
        response_transformation
    )

    AGGREGATE (
        SINGLE_GPU.out.result.mix(SINGLE_CPU.out.result).collect()
    )

    REPORT (
        AGGREGATE.out.experiment,
        'Test',
        normalization_reference
    )

}
