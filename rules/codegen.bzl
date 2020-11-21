def _codegen_impl(ctx):
    file = ctx.actions.declare_file("%s.py" % ctx.attr.key)
    ctx.actions.run(
        outputs = [file],
        executable = ctx.executable._gen_bin,
        arguments = [ctx.attr.key, file.path],
    )
    return DefaultInfo(files = depset([file]))

codegen = rule(
    implementation = _codegen_impl,
    attrs = {
        "key": attr.string(
            mandatory = True,
        ),
        "_gen_bin": attr.label(
            default = Label("//src/main/python/codegen:main"),
            executable = True,
            cfg = "host",
        ),
    },
)
