# Lab 10.1 - Sass

Creation of simple custom sass rule and its usage.

## Lab sass.1 - Dependencies

The common way for sass is to use [rules_sass](https://github.com/bazelbuild/rules_sass).
But we want our implementation to be blazing fast, so we will use use [sassc](https://github.com/sass/sassc) compiler.

So, let's first initialize the compiler and dependencies.

Create `rules/sass_deps.bzl` file with the following content (check comments):

```bazel
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# BUILD file content to be injected to libsass
LIBSASS_BUILD_FILE = """
# visible for sassc compiler only
package(default_visibility = ["@sassc//:__pkg__"])
# filegroup, containing libsass sources
filegroup(
    name = "srcs",
    srcs = glob([
        "src/**/*.h*",
        "src/**/*.c*",
    ]),
)
# define c++ library with `includes` directive,
# so sassc will know where to find c++ headers 
cc_library(
    name = "headers",
    includes = ["include"],
    hdrs = glob(["include/**/*.h"]),
)
"""

# BUILD file content to be injected to sassc compiler
SASSC_BUILD_FILE = """
package(default_visibility = ["//visibility:public"])
# c++ binary of actual compiler
cc_binary(
    name = "sassc",
    srcs = [
        "@libsass//:srcs",
        "sassc.c",
        "sassc_version.h",
    ],
    copts = ["-UDEBUG"],
    linkopts = ["-ldl", "-lm"],
    deps = ["@libsass//:headers"],
)
"""

# Bazel macros, which download libsass & sassc sources 
# We could put it right to the WORKSPACE file,
# but let's keep our dependencies clean:
def sass_repositories():
    http_archive(
        name = "libsass",
        url = "https://github.com/sass/libsass/archive/3.4.5.tar.gz",
        sha256 = "fd0cb47479b4eae03154f23e17ab846aa81ba168c9aa5fa493b8fa42d10842c8",
        build_file_content = LIBSASS_BUILD_FILE,
        strip_prefix = "libsass-3.4.5",
    )

    http_archive(
        name = "sassc",
        url = "https://github.com/sass/sassc/archive/3.4.5.tar.gz",
        sha256 = "29ea67ebeebb224feb7b0a7d76654f4868804150f8723da8d2e9c7bf6b9d64f6",
        build_file_content = SASSC_BUILD_FILE,
        strip_prefix = "sassc-3.4.5",
    )
```

Next, ensure you have `BUILD.bazel` file in `rules` directory. If there is none, create an empty one, it is important to define Bazel's package inside rules directory.

In order to initialize sass dependencies, add the following lines to the `WORKSPACE` file:

```bazel
# Sass
load("//rules:sass_deps.bzl", "sass_repositories")
sass_repositories()
```

Let's try to launch sass compiler now:

```bash
bazel run @sassc//:sassc
```

## Lab sass.2 - Simple sass_library & sass_binary rules

Create `rules/sass.bzl` file with the following content (check comments):

```bazel
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
```

## Lab sass.3 - sass_library & sass_binary example

Let's first create a shared sass library.

`src/sass/shared/fonts.scss`:

```css
// Fonts that all Sass code can share.
$default-font-stack: Cambria, "Hoefler Text", Utopia, "Liberation Serif",
"Nimbus Roman No9 L Regular", Times, "Times New Roman", serif;

$modern-font-stack: Constantia, "Lucida Bright", Lucidabright, "Lucida Serif",
Lucida, "DejaVu Serif", "Bitstream Vera Serif", "Liberation Serif", Georgia,
serif;
```

`src/sass/shared/colors.scss`:

```css
// Colors that all Sass code can share.

$example-blue: #00f;
$example-red: #f00;
$example-green: #008000;
```

And `src/sass/shared/BUILD.bazel` for it:

```bazel
load("//rules:sass.bzl", "sass_library")

# make a :shared target that includes both colors and fonts.
sass_library(
    name = "shared",
    srcs = [
        "colors.scss",
        "fonts.scss",
    ],
    visibility = ["//visibility:public"],
)
```

Ok, now we need a sass_binary, but first, let's create a main sass file.

`src/sass/helloworld/main.scss`:

```css
@import "fonts";
@import "colors";

html {
    body {
        font-family: $default-font-stack;

        h1 {
            color: $example-red;
            font-family: $modern-font-stack;
        }
    }
}
```

Now, `src/sass/helloworld/BUILD.bazel`:

```bazel
load("//rules:sass.bzl", "sass_binary")

# Import our shared colors and fonts, so we can generate a CSS file.
sass_binary(
    name = "helloworld",
    out = "helloworld.css",
    src = "main.scss",
    deps = [
        "//src/sass/shared",
    ],
    visibility = ["//visibility:public"],
)
```

Let's test it:

```bash
bazel build //src/sass/helloworld
cat bazel-bin/src/sass/helloworld/helloworld.css
```
