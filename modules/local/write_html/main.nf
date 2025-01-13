process WRITE_HTML {
    tag "${test_mode}"
    label 'process_single'

    input:
    val(run_id)
    tuple val(test_mode), path(files)

    output:
    path('*.html'), emit: html_out

    script:
    """
    write_html.py \\
        --run_id $run_id \\
        --test_mode $test_mode \\
        --files $files
    """

}
