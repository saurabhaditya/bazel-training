## Lab 6 - GRPC with Java & Go

In lab 5 we already discovered the use of Protobuf to share interfaces
between different languages, Java and Go in our case. Now we can go further
and get GRPC working via Bazel.

There is a protobuf file in this repository at
<code>src/main/proto/echo.proto</code>
which will be used by Java and Go programs at
<code>src/main/java/com/flarebuild/echo_client/EchoClient.java</code>
and <code>src/main/go/echo_server/echo_server.go</code> respectively.
In this exercise, we’ll create BUILD files for the grpc library which will be
consumed by both Java and Go applications.

### Part 1: Add dependencies for Go server code

Make sure that dependencies `golang.org/x/net` and `google.golang.org/grpc`
are in `src/main/go/echo_server/go.mod`. If not, add them via `go get`.
Then, regenerate go deps defined in `repositories.bzl` via
`bazel run //:gazelle -- update-repos --from_file=src/main/go/echo_server/go.mod -to_macro=repositories.bzl%go_repositories_echo_server`


<details>
  <summary>Hint</summary> <code>src/main/go/echo_server/go.mod</code> should look like this:

```
module echo_server

go 1.15

require (
	golang.org/x/net v0.0.0-20201110031124-69a78807bb2b // indirect
	google.golang.org/grpc v1.33.2 // indirect
)
```

</details>

### Part 2: Build the .proto files

#### 1: BUILD file for echo.proto 
In order to actually use and generate the RPC, we need to update our `proto/BUILD.bazel` file with the appropriate
build targets. Open the `proto/BUILD.bazel` file and add proto targets for echo.proto in a similar manner
as we have already for message_object.proto. List of actions: proto_library, go_proto_library, java_proto_library.

Next, you'll need to modify go_proto_library, so it supports grpc
and add a separate grpc target for java which takes proto_library as source and java_proto_library as dependency.

<details>
  <summary>Hint</summary> modify file src/main/proto/BUILD:

```bazel
proto_library(
    name = "echo_proto",
    srcs = ["echo.proto"],
    deps = [
        ":message_object_proto",
    ]
)

go_proto_library(
    name = "echo_go_proto_grpc",
    compiler = "@io_bazel_rules_go//proto:go_grpc",
    proto = ":echo_proto",
    importpath = "echo",
    deps = [":message_object_go_proto"],
    visibility = ["//src/main/go/echo_server:__pkg__"],
)

java_proto_library(
    name = "echo_java_proto",
    deps = [":echo_proto"],
    visibility = ["//src/main/java/com/flarebuild/echo_client:__pkg__"],
)

load("@io_grpc_grpc_java//:java_grpc_library.bzl", "java_grpc_library")
java_grpc_library(
    name = "echo_java_proto_grpc",
    srcs = [":echo_proto"],
    deps = [":echo_java_proto"],
    visibility = ["//src/main/java/com/flarebuild/echo_client:__pkg__"],
)
```

Let’s examine what we’ve added here. The first new build target should look familiar;
it simply defines the `proto_library` target for the `echo.proto` file. In a similar fashion,
`echo_java_proto` should also look very familiar, as it defines the build target for the Java version of echo.proto.

The `echo_go_proto_grpc` looks very similar to what we have seen previously;
the primary exception is addition of the compiler directive within go_proto_ library target.
This defines the rule that should be used when compiling the target in order to support gRPC.
We use the standard rule found within the `@io_bazel_rules_go` dependency.

Since we are using this proto library only in the `go/echo_server` package, we set the corresponding visibility.

The `java_grpc_library` does a similar job, except for defining the necessary target for Java.
In a complementary fashion, we set the visibility to only the echo_client package.

</details>

#### 2: Just to confirm that all is working well, let’s build created targets:
```bash
bazel build //src/main/proto:echo_java_proto_grpc
bazel build //src/main/proto:echo_go_proto_grpc
```

### Part 3: Create a BUILD file for the Java binary
Create a `java_binary` target using `java_proto_library`
and `java_proto_grpc_library` defined above as dependencies.

It should be located in `src/main/java/com/flarebuild/echo_client`
and run `EchoClient.java`.

After this step you could run java program via
```bash
bazel run //src/main/java/com/flarebuild/echo_client
```

<details>
  <summary>Hint</summary> Create file <code>src/main/java/com/flarebuild/echo_client/BUILD.bazel</code> with contents:

```bazel
java_binary(
    name = "echo_client",
    srcs = ["EchoClient.java"],
    main_class = "EchoClient",
    runtime_deps = [
        "@io_grpc_grpc_java//netty",
    ],
    deps = [
        "//src/main/proto:message_object_java_proto",
        "//src/main/proto:echo_java_proto",
        "//src/main/proto:echo_java_proto_grpc",
        "@io_grpc_grpc_java//api",
    ]
)
```
</details>

### Part 4: Create a BUILD file for the Go binary

Create a BUILD file such that the go program can be built
with <code>bazel build //src/main/go/echo_server:echo_server</code>
and be sure to include <code>//src/main/proto:echo_go_proto_grpc</code>,
<code>//src/main/proto:message_object_go_proto</code> as dependencies.

After this step you could run java program via
```bash
bazel run //src/main/go/echo_server
```

<details>
  <summary>Hint</summary> the file <code>src/main/go/echo_server/BUILD.bazel</code> should contain:

```bazel
load("@io_bazel_rules_go//go:def.bzl", "go_binary")

go_binary(
    name = "echo_server",
    srcs = ["echo_server.go"],
    deps = [
         "//src/main/proto:echo_go_proto_grpc",
         "//src/main/proto:message_object_go_proto",
         "@org_golang_x_net//context:go_default_library",
         "@org_golang_google_grpc//:go_default_library",
    ]
)
```

</details>
