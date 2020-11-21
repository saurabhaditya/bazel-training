# Lab 5 - Advanced Java; Protobuf with Bazel


## Lab 5.1 -  Java & 3rd-party Dependencies

<code>Rules_jvm_external</code> is already configured in this workspace; however, various applications and tests in the project will need their 3rd-party dependencies added to the Maven configuration so that <code>rules_jvm_external</code> can download them. This lab will acquaint you with that workflow in addition to the creation of BUILD files defining binary and test targets.


### Part 1: Add a Maven dependency


#### 1: Add a Maven dependency on commons-math3

Given the following Maven dependency definition, add <code>commons-math3</code> to the project.


```xml
<dependency>
   <groupId>org.apache.commons</groupId>
   <artifactId>commons-math3</artifactId>
   <version>3.1</version>
</dependency>
```

<details>
  <summary>Hint</summary> Add  <code>"org.apache.commons:commons-math3:3.1" </code>to the artifacts list of <code>maven_install</code> in the <code>WORKSPACE</code>: 


```bazel
maven_install(
   name = "maven",
   artifacts = [
       "org.apache.commons:commons-math3:3.1",
   ],
   maven_install_json = "//:maven_install.json",
   repositories = [
       "https://jcenter.bintray.com/",
       "https://maven.google.com",
       "https://repo1.maven.org/maven2",
   ],
)
```
</details>

Dependencies downloaded by <code>rules_jvm_external</code> can be accessed by at <code>@maven//:{coordinate}</code>, replacing all periods and colons with underscores and omitting the version. So commons-math3 is available at <code>@maven//:org_apache_commons_commons_math3</code>


#### 2: Pin the dependency



1. Run <code>bazel run @unpinned_maven//:pin</code>
2. Run <code>cat maven_install.json</code> and insure the entry has been added


#### 3: Bump the dependency version up

Increase the version of commons-math to 3.2.

<details>
  <summary>Hint</summary> Change  <code>"org.apache.commons:commons-math3:3.1" </code>to <code>"org.apache.commons:commons-math3:3.2" in </code>the artifacts list of <code>maven_install</code> in the <code>WORKSPACE</code>: 


```bazel
maven_install(
   name = "maven",
   artifacts = [
       "org.apache.commons:commons-math3:3.2",
   ],
   maven_install_json = "//:maven_install.json",
   repositories = [
       "https://jcenter.bintray.com/",
       "https://maven.google.com",
       "https://repo1.maven.org/maven2",
   ],
)
```
</details>


#### Part 2: Create BUILD file for ComplexGenerator

There is a Java library at <code>src/main/java/com/flarebuild/complex/generator/ComplexGenerator.java</code>. Create a BUILD file for it such that it can be built with:


```bash
bazel build //src/main/java/com/flarebuild/complex/generator:ComplexGenerator
```

Note that this library depends on <code>commons-math3. </code>

<details>
  <summary>Hint</summary> create file <code>src/main/java/com/flarebuild/complex/generator/BUILD</code> with contents:


```bazel
load("@rules_java//java:defs.bzl", "java_library")

package(default_visibility = ["//visibility:public"])

java_library(
    name = "ComplexGenerator",
    srcs = ["ComplexGenerator.java"],
    deps = [
        "@maven//:org_apache_commons_commons_math3",
    ],
)
```
</details>


## Lab 5.2 - Java Tests & Dependencies


### Part 1: Add a Maven dependency


#### 1: Add a Maven dependency on JUnit

Given the following Maven dependency definition, add <code>junit</code> to the project. Note that the test scope maps to testonly=True in the Bazel world, and that to use this property, we’ll want to use the [maven.artifact](https://github.com/bazelbuild/rules_jvm_external/blob/master/docs/api.md#mavenartifact) variant of artifact definition.


```xml
<dependency>
   <groupId>junit</groupId>
   <artifactId>junit</artifactId>
   <version>4.8.1</version>
   <scope>test</scope>
</dependency>
```


<details>
  <summary>Hint</summary> Update <code>maven_install</code> in the <code>WORKSPACE</code> to the following:


```bazel
maven_install(
   name = "maven",
   artifacts = [
       maven.artifact(
           "junit",
           "junit",
           "4.8.1",
           testonly = True,
       ),
       "org.apache.commons:commons-math3:3.2",
   ],
   maven_install_json = "//:maven_install.json",
   repositories = [
       "https://jcenter.bintray.com/",
       "https://maven.google.com",
       "https://repo1.maven.org/maven2",
   ],
)
```
</details>


#### 2: Pin the new dependency

Run <code>bazel run @unpinned_maven//:pin</code>


#### Part 2: Create a BUILD file for the ComplexGenerator tests 

There is a Java test at <code>src/test/java/com/flarebuild/complex/ComplexGeneratorTest.java</code>. Create a BUILD file for it such that it can be run with: 


```bash
bazel test //src/test/java/com/flarebuild/complex:ComplexGeneratorTest
```


<details>
  <summary>Hint</summary> Create file <code>src/test/java/com/flarebuild/complex/BUILD </code>with contents:


```bazel
load("@rules_java//java:defs.bzl", "java_library", "java_test")

java_test(
   name = "ComplexGeneratorTest",
   size = "small",
   srcs = ["ComplexGeneratorTest.java"],
   test_class = "com.flarebuild.complex.ComplexGeneratorTest",
   deps = [
       "//src/main/java/com/flarebuild/complex/generator:ComplexGenerator",
       "@maven//:junit_junit",
   ],
)
```
</details>

Invoke with  <code>bazel test //src/test/java/com/flarebuild/complex:ComplexGeneratorTest</code>



## Lab 5.3 - Protobuf with Go & Java

There is a protobuf file in this repository at <code>src/main/proto/message_object.proto</code> which will be used by Java and Go programs
at <code>src/main/java/com/flarebuild/message/Main.java</code> and <code>src/main/go/message/message.go</code>.
In this exercise, we’ll create BUILD files for the proto library which will be consumed by both Java and Go applications.


### Part 1: Build the .proto files


#### 1: Create a BUILD file for message_object 

Create a BUILD file under <code>//src/main/proto</code> and make the packages it defines publicly accessible.
Define a proto_library, and then a java_proto_library and go_proto_library targets which use it as a dep.

<details>
  <summary>Hint</summary> create file src/main/proto/BUILD: 


```bazel
load("@rules_java//java:defs.bzl", "java_proto_library")
load("@rules_proto//proto:defs.bzl", "proto_library")
load("@io_bazel_rules_go//proto:def.bzl", "go_proto_library")

package(default_visibility = ["//visibility:public"])

proto_library(
   name = "message_object_proto",
   srcs = [":message_object.proto"],
)

java_proto_library(
   name = "message_object_proto_java",
   deps = [":message_object_proto"],
)

go_proto_library(
    name = "message_object_go_proto",
    proto = ":message_object_proto",
    importpath = "message_object",
)
```

</details>

#### 2: Build the proto library targets

* <code>bazel build //src/main/proto:message_object_proto</code>
* <code>bazel build //src/main/proto:message_object_java_proto</code>
* <code>bazel build //src/main/proto:message_object_go_proto</code>


### Part 2: Create a BUILD file for the Java binary 

Create a java binary target using java proto library as dependency

Create a BUILD file such that the java program can be built with <code>bazel build //src/main/java/com/flarebuild/message:main </code>and be sure to include <code>//src/main/proto:message_object_proto_java</code> as a dependency.

<details>
  <summary>Hint</summary> Create file <code>src/main/java/com/flarebuild/message/BUILD </code>with contents: 


```bazel
load("@rules_java//java:defs.bzl", "java_binary")

java_binary(
    name = "main",
    srcs = ["Main.java"],
    main_class = "com.flarebuild.message.Main",
    deps = [
        "//src/main/proto:message_object_java_proto",
    ],
)
```
</details>


### Part 3: Create a BUILD file for the Go binary 

Create a BUILD file such that the go program can be built with <code>bazel build //src/main/go/message:message</code>
and be sure to include <code>//src/main/proto:message_object_go_proto</code> as a dependency.

<details>
  <summary>Hint</summary> the file <code>//src/main/go/message/BUILD.bazel</code> should contain:


```bazel
load("@io_bazel_rules_go//go:def.bzl", "go_binary")
go_binary(
    name = "message",
    srcs = ["message.go"],
    deps = [
         "//src/main/proto:message_object_go_proto",
    ]
)

```
</details>

### Part 4: Tighten up visibility


1. Remove <code>package(default_visibility = ["//visibility:public"]) </code>from src/main/proto/BUILD.

2. Make targets message_object_java_proto and message_object_go_proto visible exclusively to
<code>//src/main/java/com/flarebuild/message</code> and to <code>//src/main/go/message</code> respectively.

<details>
  <summary>Hint</summary> Targets now should look like this:


```bazel
java_proto_library(
    name = "message_object_java_proto",
    visibility = ["//src/main/java/com/flarebuild/message:__pkg__"],
    deps = [":message_object_proto"],
)

go_proto_library(
    name = "message_object_go_proto",
    proto = ":message_object_proto",
    importpath = "message_object",
    visibility = ["//src/main/go/message:__pkg__"],
)
```
</details>

Invoke:

*   <code>bazel run //src/main/java/com/flarebuild/message:main</code>
*   <code>bazel run //src/main/go/message:message</code>
