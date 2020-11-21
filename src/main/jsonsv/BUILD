load("//src/main/genrule:defs.bzl", "compare_files_test")

filegroup(
    name = "expected",
    srcs = ["test/expected.jsonsv"],
)

sh_test(
    name = "ext_test",
    size = "small",
    srcs = ["test/ext.sh"],
    args = [
        "$(rootpath :compile_jsonsv)",
    ],
    data = [
        ":compile_jsonsv",
    ],
)

compare_files_test(
    name = "jsonsv_test",
    actual = ":compile_jsonsv",
    expected = ":expected",
    visibility = ["//src/main/jsonsv:__pkg__"],
)
