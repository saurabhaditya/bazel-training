load("@rules_java//java:defs.bzl", "java_library", "java_test")

java_test(
    name = "ComplexGeneratorTest",
    size = "small",
    srcs = [
        "ComplexGeneratorTest.java"
    ],
    test_class = "com.flarebuild.complex.ComplexGeneratorTest",
    deps = [
        "//src/main/java/com/flarebuild/complex/generator:ComplexGenerator",
        "@maven//:junit_junit",
    ],
)
