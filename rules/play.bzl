# targets are [targets](https://docs.bazel.build/versions/master/skylark/lib/Target.html)
# and contain [DefaultInfo](https://docs.bazel.build/versions/master/skylark/lib/DefaultInfo.html) provider
# lets list files in each provider
def _flatten_default_info_targets(targets):
    result = []
    for target in targets:
        for file in target[DefaultInfo].files.to_list():
            result.append(file)
    return result

def _copy_to(actions, dir, files, strip_package = None):
    outputs = []
    for file in files:
        # path to copy to
        if not strip_package:
            # do not need to strip package
            # it is just flatten copy
            out_path = "%s/%s" % (
                dir,
                file.basename
            )
        else:
            # need to strip package
            # keep related paths
            out_path = "%s/%s" % (
                dir,
                file.short_path[len(strip_package):]
            )
        # declare output file
        out_file = actions.declare_file(out_path)
        # just run cp in shell
        actions.run_shell(
            inputs = [ file ],
            outputs = [ out_file ],
            command = "cp %s %s" % (
                file.path,
                out_file.path,
            ),
        )
        # append declared output file
        outputs.append(out_file)

    return outputs

# play module impl, just collection of runfiles actually
def _play_module_impl(ctx):
    # copy data list to make array mutable
    all_runfiles = [ f for f in ctx.files.data ]
    # copy css to public
    all_runfiles += _copy_to(ctx.actions, "public/stylesheets", _flatten_default_info_targets(ctx.attr.css))
    # copy js to public
    all_runfiles += _copy_to(ctx.actions, "public/javascripts", _flatten_default_info_targets(ctx.attr.js))

    transitive_deps = []
    for dep in ctx.attr.deps:
        # Copy all transitive jars to `lib` directory
        transitive_deps += _copy_to(ctx.actions, "lib", dep[JavaInfo].transitive_deps.to_list())

    return [
        # DefaultInfo, containing all files as runfiles
        DefaultInfo(
            runfiles = ctx.runfiles(files = all_runfiles),
        ),
        # And closure of transitive deps
        java_common.merge([dep[JavaInfo] for dep in ctx.attr.deps])
    ]

# play module rule
_play_module_rule = rule(
    attrs = {
        "data": attr.label_list(allow_files=True),
        "css": attr.label_list(providers = [DefaultInfo]),
        "js": attr.label_list(providers = [DefaultInfo]),
        # Should contain [JavaInfo](https://docs.bazel.build/versions/master/skylark/lib/JavaInfo.html) provider
        "deps": attr.label_list(providers = [JavaInfo]),
    },
    implementation = _play_module_impl,
)

def play_module(name, css = [], js = [], deps = [], visibility = None):
    _play_module_rule(
        name = name,
        data = native.glob([
            "app/**",
            "conf/**",
            "views/**",
        ]),
        css = css,
        js = js,
        deps = deps,
        visibility = visibility,
    )

def _copy_module_runfiles_impl(ctx):
    outputs = _copy_to(
        ctx.actions,
        ctx.attr.dir,
        ctx.attr.module[DefaultInfo].default_runfiles.files.to_list(),
        ctx.attr.module.label.package
    )

    return [
        # Default info with copied runfiles
        DefaultInfo(
            runfiles = ctx.runfiles(files = outputs)
        ),
        # And proxy JavaInfo, could be empty
        ctx.attr.module[JavaInfo],
    ]

_copy_module_runfiles = rule(
    attrs = {
        "module": attr.label(providers = [DefaultInfo]),
        "dir": attr.string(),
    },
    implementation = _copy_module_runfiles_impl,
)

def _copy_module_if_outside(module):
    cur_package = native.package_name()
    module_label = Label(module)
    module_package = module_label.package

    if module_package.startswith(cur_package + "/modules"):
        # this module is inside app's modules dir
        return module

    # and this module is outside app's modules dir
    # so, just copy runfiles, and return target
    _copy_module_runfiles(
        name = "_" + module_label.name + "_copy",
        module = module,
        dir = "modules/" + module_label.name,
    )

    return ":_" + module_label.name + "_copy"

# play app macro wrapper
def play_app(name, css = [], js = [], modules = [], deps = []):
    # main module:
    play_module("_" + name + "_main", css, js, deps)

    modules = ([ ":_" + name + "_main" ]
            + [ _copy_module_if_outside(m) for m in modules])

    # binary to run the app
    native.java_binary(
        name = name,
        runtime_deps = [
            # play frameworkm downloaded with ruls_jvm_external
            "@maven//:com_google_code_maven_play_plugin_org_playframework_play"
        ] + deps + modules,
        jvm_flags = [
            # play need this to be set to find all data files location
            "-Dapplication.path=" + native.package_name(),
        ],
        # just pass modules with runfiles to data
        data = modules,
        # main server class from play framework
        main_class = "play.server.Server",
    )