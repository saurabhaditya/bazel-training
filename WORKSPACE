load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "io_bazel_rules_go",
    sha256 = "207fad3e6689135c5d8713e5a17ba9d1290238f47b9ba545b63d9303406209c6",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.24.7/rules_go-v0.24.7.tar.gz",
        "https://github.com/bazelbuild/rules_go/releases/download/v0.24.7/rules_go-v0.24.7.tar.gz",
    ],
)

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

go_rules_dependencies()

go_register_toolchains()

http_archive(
    name = "bazel_gazelle",
    sha256 = "cdb02a887a7187ea4d5a27452311a75ed8637379a1287d8eeb952138ea485f7d",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-gazelle/releases/download/v0.21.1/bazel-gazelle-v0.21.1.tar.gz",
        "https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.21.1/bazel-gazelle-v0.21.1.tar.gz",
    ],
)

load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")

gazelle_dependencies()

load("//:repositories.bzl", "go_repositories_converter")

# gazelle:repository_macro repositories.bzl%go_repositories_converter
go_repositories_converter()

# java thirdparty lab start
RULES_JVM_EXTERNAL_TAG = "3.3"

RULES_JVM_EXTERNAL_SHA = "d85951a92c0908c80bd8551002d66cb23c3434409c814179c0ff026b53544dab"

http_archive(
    name = "rules_jvm_external",
    sha256 = RULES_JVM_EXTERNAL_SHA,
    strip_prefix = "rules_jvm_external-%s" % RULES_JVM_EXTERNAL_TAG,
    url = "https://github.com/bazelbuild/rules_jvm_external/archive/%s.zip" % RULES_JVM_EXTERNAL_TAG,
)

load("@rules_jvm_external//:defs.bzl", "maven_install")
load("@rules_jvm_external//:specs.bzl", "maven")

maven_install(
    name = "maven",
    artifacts = [
        "org.apache.commons:commons-math3:3.2",
        "com.google.code.maven-play-plugin.org.playframework:play:1.5.0",
    ],
    maven_install_json = "//:maven_install.json",
    repositories = [
        # Private repositories are supported through HTTP Basic auth
        # "http://username:password@localhost:8081/artifactory/my-repository",
        "https://jcenter.bintray.com/",
        "https://maven.google.com",
        "https://repo1.maven.org/maven2",
    ],
)

load("@maven//:defs.bzl", "pinned_maven_install")

pinned_maven_install()
# java thirdparty lab end

# Golang/Buildifier Lab Start (if we do one)
# Skylib is an implicit dep,
http_archive(
    name = "bazel_skylib",
    sha256 = "97e70364e9249702246c0e9444bccdc4b847bed1eb03c5a3ece4f83dfe6abc44",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.0.2/bazel-skylib-1.0.2.tar.gz",
        "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.2/bazel-skylib-1.0.2.tar.gz",
    ],
)

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()
# a shorter alternative to the above might be
#http_archive(
#    name = "com_github_bazelbuild_buildtools",
#    strip_prefix = "buildtools-master",
#    url = "https://github.com/bazelbuild/buildtools/archive/master.zip",
#)
# but going against master is failing now, this should have a commit hash and yet does not in official docs.
# todo: consider working out what a working version is, so we can use this instead of loading all of skylib above

http_archive(
    name = "com_google_protobuf",
    sha256 = "c5dc4cacbb303d5d0aa20c5cbb5cb88ef82ac61641c951cdf6b8e054184c5e22",
    strip_prefix = "protobuf-3.12.4",
    urls = ["https://github.com/protocolbuffers/protobuf/archive/v3.12.4.zip"],
)

load("@com_google_protobuf//:protobuf_deps.bzl", "protobuf_deps")

protobuf_deps()
# Golang/Buildifier Lab End

# Install proto dependencies
http_archive(
    name = "rules_proto",
    sha256 = "602e7161d9195e50246177e7c55b2f39950a9cf7366f74ed5f22fd45750cd208",
    strip_prefix = "rules_proto-97d8af4dc474595af3900dd85cb3a29ad28cc313",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_proto/archive/97d8af4dc474595af3900dd85cb3a29ad28cc313.tar.gz",
        "https://github.com/bazelbuild/rules_proto/archive/97d8af4dc474595af3900dd85cb3a29ad28cc313.tar.gz",
    ],
)

load("@rules_proto//proto:repositories.bzl", "rules_proto_dependencies", "rules_proto_toolchains")

rules_proto_dependencies()

rules_proto_toolchains()
# end proto

# Install grpc dependencies
http_archive(
    name = "io_grpc_grpc_java",
    sha256 = "3719cd1fbb2c47232fb995e13b3719980ada1b06644ae0a2d518181fbeffd9c8",
    strip_prefix = "grpc-java-1.28.1",
    urls = ["https://github.com/grpc/grpc-java/archive/v1.28.1.tar.gz"],
)

load("@io_grpc_grpc_java//:repositories.bzl", "grpc_java_repositories")

grpc_java_repositories()

# end grpc

load("//:repositories.bzl", "go_repositories_echo_server")

# gazelle:repository_macro repositories.bzl%go_repositories_echo_server
go_repositories_echo_server()

# lab 9 rules
load("//rules:repo_codegen.bzl", "repo_codegen")

repo_codegen(
    name = "repo_gen",
    keys = [
        "foo",
        "bar",
        "baz",
        "bat"
    ],
)

# Sass
load("//rules:sass_deps.bzl", "sass_repositories")
sass_repositories()

# rules_closure
http_archive(
    name = "io_bazel_rules_closure",
    sha256 = "7d206c2383811f378a5ef03f4aacbcf5f47fd8650f6abbc3fa89f3a27dd8b176",
    strip_prefix = "rules_closure-0.10.0",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_closure/archive/0.10.0.tar.gz",
        "https://github.com/bazelbuild/rules_closure/archive/0.10.0.tar.gz",
    ],
)
load("@io_bazel_rules_closure//closure:repositories.bzl", "rules_closure_dependencies", "rules_closure_toolchains")
rules_closure_dependencies()
rules_closure_toolchains()

register_toolchains(
  "//tools/cypher:cypher1_toolchain",
  "//tools/cypher:cypher5_toolchain",
  "//tools/cypher:cypher42_toolchain",
)

# Docker rules begin https://github.com/bazelbuild/rules_docker#setup
#http_archive(
#    name = "io_bazel_rules_docker",
#    sha256 = "4521794f0fba2e20f3bf15846ab5e01d5332e587e9ce81629c7f96c793bb7036",
#    strip_prefix = "rules_docker-0.14.4",
#    urls = ["https://github.com/bazelbuild/rules_docker/releases/download/v0.14.4/rules_docker-v0.14.4.tar.gz"],
#)

# from https://github.com/bazelbuild/rules_docker/releases
http_archive(
    name = "io_bazel_rules_docker",
    sha256 = "1698624e878b0607052ae6131aa216d45ebb63871ec497f26c67455b34119c80",
    strip_prefix = "rules_docker-0.15.0",
    urls = ["https://github.com/bazelbuild/rules_docker/releases/download/v0.15.0/rules_docker-v0.15.0.tar.gz"],
)
load(
    "@io_bazel_rules_docker//repositories:repositories.bzl",
    container_repositories = "repositories",
)
container_repositories()

#load("@io_bazel_rules_docker//repositories:deps.bzl", container_deps = "deps")
#container_deps()

#load(
#    "@io_bazel_rules_docker//container:container.bzl",
#    "container_pull",
#)
#container_pull(
#    name = "debian10",
#    # tag = "10.5-slim",
#    digest = "sha256:e0a33348ac8cace6b4294885e6e0bb57ecdfe4b6e415f1a7f4c5da5fe3116e02",
#    registry = "index.docker.io",
#    repository = "library/debian",
#)
#container_pull(
#    name = "java_distroless",
#    # tag = "11",
#    digest = "sha256:19ebdd790a1cd1592036644543c50f6b2d133e631ae090460701089ab0962d41",
#    registry = "gcr.io",
#    repository = "distroless/java",
#)
#
#container_pull(
#  name = "java_base",
#  registry = "gcr.io",
#  repository = "distroless/java",
#  # 'tag' is also supported, but digest is encouraged for reproducibility.
#  digest = "sha256:deadbeef",
#)
# Docker rules end


load(
    "@io_bazel_rules_docker//java:image.bzl",
    _java_image_repos = "repositories",
)

_java_image_repos()