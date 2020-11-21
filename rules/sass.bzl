# Sass files extensions
SASS_FILETYPES = (
    ".sass",
    ".scss",
    ".css",
)

# for each dep in ctx, collect its transitive_sass_files output
def _collect_transitive_sources(ctx):
    return depset(
        transitive = [
            dep.transitive_sass_files
            if hasattr(dep.transitive_sass_files, "to_list") else
            depset(dep.transitive_sass_files)
            for dep in ctx.attr.deps
        ],
        order = "preorder",
    )

# Sass library rule implementation
def _sass_library_impl(ctx):
    # for each dep in ctx, collect its transitive_sass_files output
    transitive_sources = _collect_transitive_sources(ctx)
    exports = [export.transitive_sass_files for export in ctx.attr.exports]
    # filter sass files by extension
    sass_files = depset([src for src in ctx.files.srcs if src.path.endswith(SASS_FILETYPES)])

    # compose all source files
    transitive_sass_files = depset(
        transitive = [sass_files] + exports + [transitive_sources],
        order = "preorder",
    )

    # return a struct, which contains all files
    return struct(
        files = depset(),
        transitive_sass_files = transitive_sass_files,
    )

sass_deps_attr = attr.label_list(
    providers = ["transitive_sass_files"],
    allow_files = False,
)

# Defines a collection of Sass files that can be depended on by a sass_binary.
# Does not generate any outputs.
sass_library = rule(
    attrs = {
        # list of sass files with extensions from SASS_FILETYPES
        "srcs": attr.label_list(
            allow_files = SASS_FILETYPES,
        ),
        "deps": sass_deps_attr,
        "exports": sass_deps_attr,
    },
    implementation = _sass_library_impl,
)

# Sass binary rule implementation
def _sass_binary_impl(ctx):
    sassc = ctx.file._sassc

    # sass compiler options (for reference https://github.com/sass/sassc)
    options = [
        "--sourcemap",
    ]

    if ctx.attr.dev_mode:
        options.append("--line-numbers")
        options.append("--style=expanded")
    else:
        options.append("--style=compressed")

    # Load up all the transitive sources as dependent includes.
    transitive_sources = _collect_transitive_sources(ctx).to_list()

    # Load transitive source folders
    transitive_source_folders = depset(
        [src.dirname for src in transitive_sources],
        order = "preorder",
    )

    # apply load path
    for src_folder in transitive_source_folders.to_list():
        options += ["--load-path={}".format(src_folder)]

    srcs = ctx.attr.src.files.to_list()

    # Actual sass compiler invocation
    ctx.actions.run(
        inputs = srcs +
                list(ctx.files.deps) +
                transitive_sources,
        executable = sassc,
        arguments = options + [src.path for src in srcs] + [ctx.outputs.css_file.path],
        mnemonic = "SassCompiler",
        outputs = [
            ctx.outputs.css_file,
            ctx.outputs.map_file,
        ],
    )

    # return DefaultInfo (https://docs.bazel.build/versions/master/skylark/lib/DefaultInfo.html) provider
    return DefaultInfo(
        files = depset([
            ctx.outputs.css_file,
            ctx.outputs.map_file,
        ]),
    )

# Sass binary rule, outputs generated css file
sass_binary = rule(
    attrs = {
        # Main sass file with extension from SASS_FILETYPES
        "src": attr.label(
            allow_files = SASS_FILETYPES,
            mandatory = True,
        ),
        # Output file name
        "out": attr.string(mandatory = True),
        # List of sass_library targets to depend on
        "deps": sass_deps_attr,
        "dev_mode": attr.bool(default = True),
        # Sassc compiler binary
        "_sassc": attr.label(
            default = Label("@sassc//:sassc"),
            executable = True,
            cfg = "host",
            allow_single_file = True,
        ),
    },
    # Outputs, produced by the rule, css & mappings file
    outputs = {
        "css_file": "%{out}",
        "map_file": "%{out}.map",
    },
    implementation = _sass_binary_impl,
)