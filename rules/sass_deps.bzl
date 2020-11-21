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