process WRITE_INDEX {
    //tag "index"
    label 'process_single'

    //conda "conda-forge::python=3.8.3"
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/python:3.8.3' :
    //    'biocontainers/python:3.8.3' }"

    input:
    val(run_id)
    val(test_modes)
    val(nr_html_files)

    output:
    path('*.html'), emit: html_out
    path('*.png'), emit: graphic_elements

    script:
    """
    #!/usr/bin/env python
    import shutil
    import importlib.resources as pkg_resources
    from drevalpy.visualization.utils import parse_layout

    files_to_copy = [
        "favicon.png",
        "nf-core-drugresponseeval_logo_light.png",
    ]
    for file in files_to_copy:
        file_path = str(pkg_resources.files("drevalpy").joinpath("visualization/style_utils", file))
        shutil.copyfile(file_path, file)

    layout_path = str(pkg_resources.files("drevalpy").joinpath("visualization/style_utils/index_layout.html"))

    with open("index.html", "w") as f:
        parse_layout(f=f, path_to_layout=layout_path)
        f.write('<div class="main">\\n')
        f.write('<img src="nf-core-drugresponseeval_logo_light.png" width="364px" height="100px" alt="Logo">\\n')
        f.write("<h1>Results for $run_id</h1>\\n")
        f.write("<h2>Available settings</h2>\\n")
        f.write('<div style="display: inline-block;">\\n')
        f.write("<p>Click on the images to open the respective report in a new tab.</p>\\n")
        settings = '$test_modes'.split(",")
        settings.sort()
        for setting in settings:
            img_path = str(pkg_resources.files("drevalpy").joinpath("visualization/style_utils", f"{setting}.png"))
            shutil.copyfile(img_path, f"{setting}.png")
            f.write(
                f'<a href="{setting}.html" target="_blank"><img src="{setting}.png" style="width:300px;height:300px;"></a>\\n'
            )
        f.write("</div>\\n")
        f.write("</div>\\n")
        f.write("</body>\\n")
        f.write("</html>\\n")
    """

}
