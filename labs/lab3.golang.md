# Lab 3 - Introducing rules_go and Gazelle

In this lab we will get familiar with building go binaries under Bazel using `rules_go`.

As you already know, Bazel needs to be aware of all dependencies at Analysis phase,
before running build itself (at Execution phase).

Defining all dependencies for rules_go can be time-consuming, especially for large and complicated projects.

Luckily for us, there is a tool just for that.

In order to help us generate and update `BUILD` files for `rules_go`, we will use `Gazelle`.


## Check out converter app

We have a small one-purpose app. It could convert `csv` files in pre-defined format to `json` and vice versa.

Have a look:

```bash
cd src/main/go/converter
go run main.go --help
go run main.go --in "$PWD/test/expected.json"
go test -v
``` 

Now we want to build and test this app with Bazel.

## [Setup rules_go](https://github.com/bazelbuild/rules_go#setup)

Follow the link to get instructions to update your `WORKSPACE` file.

<details>
  <summary>Hint</summary> WORKSPACE file updates:
  
```bazel
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
```
</details>

Our app has only one external package dependency: `github.com/gocarina/gocsv` (ok, there is one more for tests: `github.com/stretchr/testify/assert`).

To add it to our `BUILD` file we will need Gazelle (to do all the work of downloading and instantiating
 dependencies to be later consumed in the `go_library` and `go_binary` rules).


## [Setup Gazelle](https://github.com/bazelbuild/bazel-gazelle#running-gazelle-with-bazel)

You can run Gazelle as a separate binary, but it is better to have all build-time tooling in one place.

So, let’s add Gazelle to our `WORKSPACE` to run it with Bazel the same way as other targets.

<details>
  <summary>Hint</summary> WORKSPACE file updates:
  
```bazel
http_archive(
    name = "bazel_gazelle",
    sha256 = "cdb02a887a7187ea4d5a27452311a75ed8637379a1287d8eeb952138ea485f7d",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-gazelle/releases/download/v0.21.1/bazel-gazelle-v0.21.1.tar.gz",
        "https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.21.1/bazel-gazelle-v0.21.1.tar.gz",
    ],
)

load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies", "go_repository")

gazelle_dependencies()
```
</details>

Add gazelle target to the root `BUILD` file:

```bazel
load("@bazel_gazelle//:def.bzl", "gazelle")

# gazelle:prefix training-labs
gazelle(name = "gazelle")
```

To collect dependencies from existing `go.mod` and create a handy macro, now run this target with `update-repos --from_file=... -to_macro=...` arguments:

```bash
bazel run //:gazelle -- update-repos --from_file=src/main/go/converter/go.mod -to_macro=repositories.bzl%go_repositories_converter
```

Gazelle will create or update `repositories.bzl` which will contain a macro (we will talk about macros in more detail later) with a bunch of `go_repository` rules inside.

Macro will be created with a name defined after `%` in the `-to_macro=` argument.

[`go_repository` from gazelle](https://github.com/bazelbuild/bazel-gazelle/blob/master/internal/go_repository.bzl) is a repository (aka workspace) rule which
 purpose is to download go packages, so [`go_library` rule](https://github.com/bazelbuild/rules_go/blob/master/go/private/rules/library.bzl) could consume it later.

Load it in your `WORKSPACE` file and call the macro by its name (`go_repositories_converter`).


<details>
  <summary>Hint</summary> WORKSPACE file updates:
  
```bazel  
load("//:repositories.bzl", "go_repositories_converter")

go_repositories_converter()
```
</details>

## Generate BUILD file for `converter` app

Now, let’s use Gazelle again, this time to generate BUILD files for our apps:

```bash
bazel run //:gazelle
```

It will *automagically* scan workspace for `.go` files and create packages alongside.

Check out newly-created `src/main/go/converter/BUILD.bazel` file.

Notice not only `go_binary` target were automatically created, but `go_test` too.

## Build and run app

`bazel run` command will also invoke build step for you (same as `go run`).

To not confuse Bazel with app arguments, pass any additional app arguments after `--` (same as you did for Gazelle) 

Note you don’t need to write full target name `//src/main/go/converter:converter` (remember target anatomy), just use shorthand:

```bash
# cd src/main/go/converter
bazel run //src/main/go/converter -- --help
bazel run //src/main/go/converter -- --in "$PWD/test/expected.json"
```


## Run tests

```bash
bazel test //src/main/go/converter:go_default_test
```

You will notice test failed:

```log
==================== Test output for //src/main/go/converter:go_default_test:
2020/11/18 09:00:00: could not read file: test/expected.json
================================================================================
```

Tip: By default test output goes to `bazel-testlogs/%PACKAGE_NAME%/%TARGET_NAME%/test.log`.

For `//src/main/go/converter:go_default_test` it will be `bazel-testlogs/src/main/go/converter/go_default_test/test.log`.

With `--test_output=all` [argument](https://docs.bazel.build/versions/master/command-line-reference.html#flag--test_output) 
you will get it also printed in the terminal (check out `.bazelrc`).

Now, if you look closely at `src/main/go/converter/main_test.go` source, you will notice that the test actually depends on some files from the `test` dir.

Bazel is not aware of those dependencies (and neither is Gazelle, so it could not automatically setup those in the `BUILD` file for Bazel).

Let’s define them in the data argument of the `go_test` rule.

<details>
  <summary>Hint</summary> BUILD file updates:
  
```bazel
go_test(
    name = "go_default_test",
    srcs = ["main_test.go"],
    embed = [":go_default_library"],
    deps = ["@com_github_stretchr_testify//assert:go_default_library"],
    data = glob(["test/**"]),
    size="small",
)
```

Or, in a more granular way:

```bazel
go_test(
    #...
    data = [
        "test/expected.csv",
        "test/expected.json",
    ],
)
```
</details>

Now all tests should pass successfully.
