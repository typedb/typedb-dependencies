# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


def _checkstyle_test_impl(ctx):
    properties = ctx.file.properties
    opts = ctx.attr.opts
    sopts = ctx.attr.string_opts

    args = ""
    inputs = []

    expected_file = "checkstyle-file-%s.txt" % ctx.attr.license_type
    matched = False
    for license_file in ctx.attr._license_files[0].files.to_list():
        if license_file.basename == expected_file:
            matched = True
            break
    if not matched:
        fail("Could not find license file matching: %s" % expected_file)

    config = ctx.actions.declare_file("%s.xml" % ctx.attr.name)
    ctx.actions.expand_template(
        template = ctx.file._checkstyle_xml_template,
        output = config,
        substitutions = {
            "{licenseFile}" : license_file.short_path
        }
    )

    args += " -c "
    if ctx.label.package:
        args += ctx.label.package + '/'
    args += config.basename

    inputs.append(config)

    if properties:
      args += " -p %s" % properties.short_path
      inputs.append(properties)

    files = []
    for target in ctx.attr.include:
        path = target.files.to_list()[0].path;
        if target not in ctx.attr.exclude:
            files.extend(target.files.to_list())

    classpath = ":".join([file.short_path for file in ctx.files._classpath])
    cmd = " ".join(
        ["java -cp %s com.puppycrawl.tools.checkstyle.Main" % classpath] +
        [args] +
        ["--%s" % x for x in opts] +
        ["--%s %s" % (k, sopts[k]) for k in sopts] +
        [file.short_path for file in files]
    )

    checkstyle_wrapper = ctx.actions.declare_file("%s.sh" % ctx.attr.name)
    ctx.actions.write(
        output = checkstyle_wrapper,
        content = cmd,
        is_executable = True,
    )

    files = [checkstyle_wrapper] + ctx.files._license_files + files + ctx.files._classpath + inputs
    runfiles = ctx.runfiles(
        files = files,
        collect_data = True,
    )
    return DefaultInfo(
        executable = checkstyle_wrapper,
        files = depset(files),
        runfiles = runfiles,
    )

checkstyle_test = rule(
    implementation = _checkstyle_test_impl,
    test = True,
    attrs = {
        "license_type": attr.string(
            doc = "Type of license to produce the header for every source code",
            values = [
                "mpl-header",
                "apache-header",
                "commercial-header",
                "mpl-fulltext",
                "apache-fulltext",
                "commercial-fulltext",
            ],
            mandatory = True,
        ),
        "properties": attr.label(
            allow_single_file=True,
            doc = "A properties file to be used"
        ),
        "opts": attr.string_list(
            doc = "Options to be passed on the command line that have no argument"
        ),
        "string_opts": attr.string_dict(
            doc = "Options to be passed on the command line that have an argument"
        ),
        "include": attr.label_list(
            doc = "A list of files that should be checked",
            allow_files = True,
        ),
        "exclude": attr.label_list(
            doc = "A list of files that should be excluded from checking (in addition to the default exclusions)",
            allow_files = True,
            default = [],
        ),
        "_checkstyle_xml_template": attr.label(
             allow_single_file=True,
             default = "//tool/checkstyle/templates:checkstyle.xml"
        ),
        "_classpath": attr.label_list(default=[
            Label("@com_puppycrawl_tools_checkstyle//file"),
            Label("@commons_beanutils_commons_beanutils//file"),
            Label("@info_picocli_picocli//file"),
            Label("@commons_collections_commons_collections//file"),
            Label("@org_slf4j_slf4j_api//file"),
            Label("@org_slf4j_slf4j_jcl//file"),
            Label("@antlr_antlr//file"),
            Label("@org_antlr_antlr4_runtime//file"),
            Label("@com_google_guava_guava30jre//file"),
        ]),
        "_license_files": attr.label_list(
            allow_files=True,
            doc = "License file(s) that can be used with the checkstyle license target",
            default = ["@typedb_dependencies//tool/checkstyle/config:license_files"]
        ),
    },
)
