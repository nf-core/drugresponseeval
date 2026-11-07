process WRITE_BEST_HPAM {
    tag "${test_mode}_${model_name}_${split_id}"
    label 'process_single'

    input:
    // val, not path: exec processes do not stage inputs, a path would only be the file name
    tuple val(model_name), val(test_mode), val(split_id), val(hpam_yaml)

    output:
    tuple val(model_name), val(split_id), val(test_mode), path('best_hpam_combi_*.yaml'), emit: best_combis

    exec:
    // without hyperparameter tuning there is only one combination, so it is the best one, in the format of EVALUATE_FIND_MAX
    def yaml = new org.yaml.snakeyaml.Yaml()
    def best = [("${model_name}_${split_id}".toString()): [best_hpam_combi: yaml.load(hpam_yaml.text)]]
    task.workDir.resolve("best_hpam_combi_${split_id}.yaml").text = yaml.dump(best)
}
