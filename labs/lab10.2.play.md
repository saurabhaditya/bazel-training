# Lab 10.2 - Play

Creation of simple custom play framework rule and it's usage.

## Lab play.1 - Dependencies

In the `Advanced Java` lab, you were introduced to `rules_jvm_external`, a tool to resolve & download maven dependencies.
Now we'll use it to download `play framework`.

In `WORKSPACE`, find `maven_install` rule, and add:
    
    "com.google.code.maven-play-plugin.org.playframework:play:1.5.0"

to `artifacts` args, just like this:

```bazel
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
```

Run:

```bash
bazel run @unpinned_maven//:pin
```

to resolve all dependencies and produce `maven_install.json` lock file.

```bash
bazel build @maven//:com_google_code_maven_play_plugin_org_playframework_play
```

to ensure success.

## Lab play.2 - Play App helloworld template

Now, we have to create simple hello world application.

Create the following files:

`src/main/play/helloworld/app/controllers/Application.java`:

```java
package controllers;

import java.util.*;
import play.*;
import play.mvc.*;

public class Application extends Controller {

    public static void index() {
        render();
    }
}
```

`src/main/play/helloworld/app/views/Application/index.html`:

```
#{extends 'main.html' /}
```

`src/main/play/helloworld/app/views/main.html`:

```html
<html>
<head>
</head>
<body>
    <h1>Hello World</h1>
    <h2>Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna
    aliqua.</h2>
</body>
</html>
```

`src/main/play/helloworld/app/views/errors/404.html`:

```
404
```

`src/main/play/helloworld/app/views/errors/500.html`:

```
500
```

`src/main/play/helloworld/conf/application.conf`:

```
application.name=helloworld
application.mode=dev
```

`src/main/play/helloworld/conf/routes`:

```
GET     /                                       Application.index
```

`src/main/play/helloworld/conf/dependencies.yml`:

```yaml
require:
    - play
```

Create an empty file named `src/main/play/helloworld/conf/messages`.

## Lab play.3 - Custom Play app rule, 1st iteration

Now that we have created a template, let's wrap it with a simple custom Bazel rule.

Create `rules/play.bzl`, with content (check comments):

```bazel
# play app macro wrapper
def play_app(name):
    # Play app template files
    data = native.glob([
        "app/**",
        "conf/**",
        "views/**",
    ])

    # binary to run the app
    native.java_binary(
        name = name,
        runtime_deps = [ 
            # play framework downloaded with ruls_jvm_external
            "@maven//:com_google_code_maven_play_plugin_org_playframework_play" 
        ],
        jvm_flags = [ 
            # play need this to be set to find all data files location
            "-Dapplication.path=" + native.package_name(),
        ],
        data = data,
        # main server class from play framework
        main_class = "play.server.Server",
    )
```

Then `src/main/play/helloworld/BUILD.bazel`:

```bazel
load("//rules:play.bzl", "play_app")

play_app(
    name = "helloworld",
)
```

Let's test it:

```bash
bazel run //src/main/play/helloworld
```

Now open `http://127.0.0.1:9000/` in browser.

## Lab play.4 - Adding sass

In `sass` lab, we explored with css from sass generation.

Let's apply the same technique here.

We need to copy css files to be available for play app binary.
We can do it with Bazel's [runfiles](https://docs.bazel.build/versions/master/skylark/lib/runfiles.html) mechanism.

First, lets extend `rules/play.bzl` with copy to runfiles rule (check comments):

```bazel
def _copy_to_impl(ctx):
    outputs = []
    for files in ctx.attr.files:
        # files are [targets](https://docs.bazel.build/versions/master/skylark/lib/Target.html)
        # and contain [DefaultInfo](https://docs.bazel.build/versions/master/skylark/lib/DefaultInfo.html) provider
        # lets list files in each provider
        for file in files[DefaultInfo].files.to_list():
            # path to copy to
            out_path = "%s/%s" % (
                ctx.attr.dir,
                file.basename
            )
            # declare output file
            out_file = ctx.actions.declare_file(out_path)
            # just run cp in shell
            ctx.actions.run_shell(
                inputs = [ file ],
                outputs = [ out_file ],
                command = "cp %s %s" % (
                    file.path,
                    out_file.path,
                ),
            )
            # append declared output file
            outputs.append(out_file)
    
    # and return DefaultInfo, containing all copied files as runfile
    return DefaultInfo(runfiles = ctx.runfiles(files = outputs))

_copy_to_rule = rule(
    attrs = {
        # files targets list
        # we expect each target to have [DefaultInfo](https://docs.bazel.build/versions/master/skylark/lib/DefaultInfo.html) provider
        "files": attr.label_list(providers = [DefaultInfo]),
        "dir": attr.string(),
    },
    implementation = _copy_to_impl,
)

# copy macro
def _copy_to(name, dir, files):
    if not files:
        return []

    # define copy rule
    _copy_to_rule(
        name = name + "_copy_css",
        dir = dir,
        files = files,
    )

    # and return it's ;abel
    return [ ":" + name + "_copy_css" ]

# play app macro wrapper
def play_app(name, css):
    # Play app template files
    data = native.glob([
        "app/**",
        "conf/**",
        "views/**",
    ])

    # copy css to public/stylesheets and add to data files
    data += _copy_to(name, "public/stylesheets", css)

    # binary to run the app
    native.java_binary(
        name = name,
        runtime_deps = [ 
            # play framework downloaded with ruls_jvm_external
            "@maven//:com_google_code_maven_play_plugin_org_playframework_play" 
        ],
        jvm_flags = [ 
            # play need this to be set to find all data files location
            "-Dapplication.path=" + native.package_name(), 
        ],
        data = data,
        # main server class from play framework
        main_class = "play.server.Server",
    )

```

Now that we've copied the css files to the public/stylesheets dir, 
let's configure our app to use this css.

`src/main/play/helloworld/app/views/main.html`:

```html
<html>
<head>
    <link rel="stylesheet" media="screen" href="@{'/public/stylesheets/helloworld.css'}">
</head>

<body>
    <h1>Hello World</h1>
    <h2>Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna
    aliqua.</h2>
</body>

</html>
```

`src/main/play/helloworld/conf/routes`:

```
GET     /                                       Application.index
GET     /public/                                staticDir:public
```

And specify css in `src/main/play/helloworld/BUILD.bazel`:

```bazel
load("//rules:play.bzl", "play_app")

play_app(
    name = "helloworld",
    css = [ "//src/sass/helloworld" ],
)
```

Rerun our app:

```bash
bazel run //src/main/play/helloworld
```

And see changes at `http://127.0.0.1:9000/`

## Lab play.4 - Module & closure templates

In Lab8 we used closure_js_template_library. 
The Play framework has a module system;  Let's extend our custom rule with module support, 
and this module will include closure template usage.

First, let's define our module files.

`src/main/play/helloworld/modules/greeter/conf/routes`

```
GET     /?                                      Greeter.index
GET     /public/                                staticDir:public
```

`src/main/play/helloworld/modules/greeter/app/controllers/Greeter.java`:

```java
package controllers;

import java.util.*;
import play.*;
import play.mvc.*;

public class Greeter extends Controller {
    public static void index(String name) {
        render(name);
    }
}
```

Now, let's specify `closure_binary` calling closure template instantiation:

`src/main/play/helloworld/modules/greeter/src/call_greeter.js`:

```js
goog.require('templates.Greeter');

new templates.Greeter(window.name).greet();
```

`src/main/play/helloworld/modules/greeter/src/BUILD.bazel`:

```bazel
load(
    "@io_bazel_rules_closure//closure:defs.bzl", 
    "closure_js_library",
    "closure_js_binary",
)

closure_js_library(
    name = "call_greeter",
    srcs = [ "call_greeter.js" ],
    deps = [ "//src/main/closure/templates:greeter_lib", ],
)

closure_js_binary(
    name = "call_greeter_bin",
    deps = [ ":call_greeter", ],
    formatting = "PRETTY_PRINT",
    visibility = ["//visibility:public"]
)
```

`src/main/play/helloworld/modules/greeter/app/views/Greeter/index.html`:

```html
<html>
<head>
</head>
<body>
</body>
</html>

@* storing name in window *@
<script> window.name = "${ name ?: 'guest' }"; </script>
@* call ours greeter template *@
<script src="@{'/public/javascripts/call_greeter_bin.js'}" type="text/javascript">
</script>
```

Now we need to extend our `play.bzl` with a module rule.

A Play module in  the context of bazel is just set of runfiles.

Make the following changes:

`rules/play.bzl` (check comments):

```bazel
# just function now
def _copy_to(actions, dir, files):
    outputs = []
    for files in files:
        # files are [targets](https://docs.bazel.build/versions/master/skylark/lib/Target.html)
        # and  [DefaultInfo](https://docs.bazel.build/versions/master/skylark/lib/DefaultInfo.html) provider
        # lets list files in each provider
        for file in files[DefaultInfo].files.to_list():
            # path to copy to
            out_path = "%s/%s" % (
                dir,
                file.basename
            )
            # declare output file
            out_file = actions.declare_file(out_path)
            # just run cp in shell
            actions.run_shell(
                inputs = [ file ],
                outputs = [ out_file ],
                command = "cp %s %s" % (
                    file.path,
                    out_file.path,
                ),
            )
            # append declared output file
            outputs.append(out_file)
    
    return outputs

# play module impl, just collection of runfiles actually
def _play_module_impl(ctx):
    # copy data list to make array mutable
    all_runfiles = [ f for f in ctx.files.data ]
    # copy css to public
    all_runfiles += _copy_to(ctx.actions, "public/stylesheets", ctx.attr.css)
    # copy js to public
    all_runfiles += _copy_to(ctx.actions, "public/javascripts", ctx.attr.js)

    # and return DefaultInfo, containing all files as runfiles
    return DefaultInfo(
        runfiles = ctx.runfiles(files = all_runfiles)
    )

# play module rule
_play_module_rule = rule(
    attrs = {
        "data": attr.label_list(allow_files=True),
        "css": attr.label_list(providers = [DefaultInfo]),
        "js": attr.label_list(providers = [DefaultInfo]),
    },
    implementation = _play_module_impl,
)

def play_module(name, css = [], js = [], visibility = None):
    _play_module_rule(
        name = name,
        data = native.glob([
            "app/**",
            "conf/**",
            "views/**",
        ]),
        css = css,
        js = js,
        visibility = visibility,
    )


# play app macro wrapper
def play_app(name, css = [], js = [], modules = []):
    # main module:
    play_module("_" + name + "_main", css, js)
    # binary to run the app
    native.java_binary(
        name = name,
        runtime_deps = [ 
            # play frameworkm downloaded with ruls_jvm_external
            "@maven//:com_google_code_maven_play_plugin_org_playframework_play" 
        ],
        jvm_flags = [ 
            # play need this to be set to find all data files location
            "-Dapplication.path=" + native.package_name(), 
        ],
        # just pass modules with runfiles to data
        data = [ ":_" + name + "_main" ] + modules,
        # main server class from play framework
        main_class = "play.server.Server",
    )

```

Finally, lets define our module in Bazel.

`src/main/play/helloworld/modules/greeter/BUILD.bazel`:

```bazel
load("//rules:play.bzl", "play_module")

play_module(
    name = "greeter",
    js = [ "//src/main/play/helloworld/modules/greeter/src:call_greeter_bin", ],
    visibility = ["//visibility:public"],
)
```

And link the module to the application.

`src/main/play/helloworld/BUILD.bazel`:

```bazel
load("//rules:play.bzl", "play_app")

play_app(
    name = "helloworld",
    css = [ "//src/sass/helloworld" ],
    modules = [ 
        "//src/main/play/helloworld/modules/greeter",
    ],
)
```

`src/main/play/helloworld/conf/routes`

```
GET     /                                       Application.index
GET     /public/                                staticDir:public
GET     /greet                                  module:greeter
```

`src/main/play/helloworld/conf/dependencies.yml`:

```yaml
require:
    - play
    - play -> greeter latest.integration
```

Lets test it:

```bash
bazel run src/main/play/helloworld
```

And navigate to `http://127.0.0.1:9000/greet?name=happy_bazel_user`!

## Lab play.5 - External Module & 3rd-party java library

For a more realistic example, let's look at an external module and a 3rd-party java dependency

We'll define our new play module outside of the `src/main/play/helloworld/modules` directory.

As usual, start with a new module definition.

`src/main/play/random/app/controllers/Random.java`:

```java
package controllers;

import java.util.*;
import org.apache.commons.math3.random.RandomDataGenerator;
import play.*;
import play.mvc.*;

public class Random extends Controller {

    public static void index() {
        String random = new RandomDataGenerator().nextSecureHexString(16);
        render(random);
    }
}

```

`src/main/play/random/app/views/Random/index.html`:

```html
<html>
<head>
</head>
<body>
    <h1>${random}</h1>
</body>
</html>
```

`src/main/play/random/conf/routes`:

```
GET     /?                                      Random.index
```

And, now, the final state of our play wrapper rule, 
with java libraries dependencies support and external modules.

`rules/play.bzl` (check comments):

```bazel
# targets are [targets](https://docs.bazel.build/versions/master/skylark/lib/Target.html)
# and contain [DefaultInfo](https://docs.bazel.build/versions/master/skylark/lib/DefaultInfo.html) provider
# lets list files in each provider
def _flatten_default_info_targets(targets):
    result = []
    for target in targets:
        for file in target[DefaultInfo].files.to_list():
            result.append(file)
    return result

def _copy_to(actions, dir, files, strip_package = None):
    outputs = []
    for file in files:
        # path to copy to
        if not strip_package:
            # do not need to strip package
            # it is just flatten copy
            out_path = "%s/%s" % (
                dir,
                file.basename
            )
        else:
            # need to strip package
            # keep related paths
            out_path = "%s/%s" % (
                dir,
                file.short_path[len(strip_package):]
            )
        # declare output file
        out_file = actions.declare_file(out_path)
        # just run cp in shell
        actions.run_shell(
            inputs = [ file ],
            outputs = [ out_file ],
            command = "cp %s %s" % (
                file.path,
                out_file.path,
            ),
        )
        # append declared output file
        outputs.append(out_file)
    
    return outputs

# play module impl, just collection of runfiles actually
def _play_module_impl(ctx):
    # copy data list to make array mutable
    all_runfiles = [ f for f in ctx.files.data ]
    # copy css to public
    all_runfiles += _copy_to(ctx.actions, "public/stylesheets", _flatten_default_info_targets(ctx.attr.css))
    # copy js to public
    all_runfiles += _copy_to(ctx.actions, "public/javascripts", _flatten_default_info_targets(ctx.attr.js))
    
    transitive_deps = []
    for dep in ctx.attr.deps:
        # Copy all transitive jars to `lib` directory
        transitive_deps += _copy_to(ctx.actions, "lib", dep[JavaInfo].transitive_deps.to_list())
        
    return [
        # DefaultInfo, containing all files as runfiles
        DefaultInfo(
            runfiles = ctx.runfiles(files = all_runfiles),
        ),
        # And closure of transitive deps
        java_common.merge([dep[JavaInfo] for dep in ctx.attr.deps])
    ]

# play module rule
_play_module_rule = rule(
    attrs = {
        "data": attr.label_list(allow_files=True),
        "css": attr.label_list(providers = [DefaultInfo]),
        "js": attr.label_list(providers = [DefaultInfo]),
        # Should contain [JavaInfo](https://docs.bazel.build/versions/master/skylark/lib/JavaInfo.html) provider
        "deps": attr.label_list(providers = [JavaInfo]),
    },
    implementation = _play_module_impl,
)

def play_module(name, css = [], js = [], deps = [], visibility = None):
    _play_module_rule(
        name = name,
        data = native.glob([
            "app/**",
            "conf/**",
            "views/**",
        ]),
        css = css,
        js = js,
        deps = deps,
        visibility = visibility,
    )

def _copy_module_runfiles_impl(ctx):
    outputs = _copy_to(
        ctx.actions, 
        ctx.attr.dir, 
        ctx.attr.module[DefaultInfo].default_runfiles.files.to_list(),
        ctx.attr.module.label.package
    )

    return [
        # Default info with copied runfiles
        DefaultInfo(
            runfiles = ctx.runfiles(files = outputs)
        ),
        # And proxy JavaInfo, could be empty
        ctx.attr.module[JavaInfo],
    ]

_copy_module_runfiles = rule(
    attrs = {
        "module": attr.label(providers = [DefaultInfo]),
        "dir": attr.string(),
    },
    implementation = _copy_module_runfiles_impl,
)

def _copy_module_if_outside(module):
    cur_package = native.package_name()
    module_label = Label(module)
    module_package = module_label.package

    if module_package.startswith(cur_package + "/modules"):
        # this module is inside app's modules dir
        return module

    # and this module is outside app's modules dir
    # so, just copy runfiles, and return target
    _copy_module_runfiles(
        name = "_" + module_label.name + "_copy",
        module = module,
        dir = "modules/" + module_label.name,
    )

    return ":_" + module_label.name + "_copy"

# play app macro wrapper
def play_app(name, css = [], js = [], modules = [], deps = []):
    # main module:
    play_module("_" + name + "_main", css, js, deps)

    modules = ([ ":_" + name + "_main" ] 
            + [ _copy_module_if_outside(m) for m in modules])

    # binary to run the app
    native.java_binary(
        name = name,
        runtime_deps = [ 
            # play frameworkm downloaded with ruls_jvm_external
            "@maven//:com_google_code_maven_play_plugin_org_playframework_play" 
        ] + deps + modules,
        jvm_flags = [ 
            # play need this to be set to find all data files location
            "-Dapplication.path=" + native.package_name(), 
        ],
        # just pass modules with runfiles to data
        data = modules,
        # main server class from play framework
        main_class = "play.server.Server",
    )
```

Let's instantiate our module rule in the BUILD file.

`src/main/play/random/BUILD.bazel`:

```bazel
load("//rules:play.bzl", "play_module")

play_module(
    name = "random",
    deps = [ "@maven//:org_apache_commons_commons_math3", ],
    visibility = ["//visibility:public"],
)
```

Now, link with the app.

`src/main/play/helloworld/BUILD.bazel`:

```bazel
load("//rules:play.bzl", "play_app")

play_app(
    name = "helloworld",
    css = [ "//src/sass/helloworld" ],
    modules = [ 
        "//src/main/play/helloworld/modules/greeter",
        "//src/main/play/random",
    ],
)
```

`src/main/play/helloworld/conf/routes`

```
GET     /                                       Application.index
GET     /public/                                staticDir:public
GET     /greet                                  module:greeter
GET     /random                                 module:random
```

`src/main/play/helloworld/conf/dependencies.yml`:

```yaml
require:
    - play
    - play -> greeter latest.integration
    - play -> random latest.integration
```

Lets test it:

```bash
bazel run src/main/play/helloworld
```

And navigate to `http://127.0.0.1:9000/random`!

## Lab play.6 - Play & ibazel

For a better developer experience, we'll use [ibazel](https://github.com/bazelbuild/bazel-watcher) 
to watch for changes to our running application and automatically rebuild it for us so we don't 
need to stop and start the server manually to see our changes rebuilt and reflected in the app.

To install for mac:

```bash
brew tap bazelbuild/tap
brew install bazelbuild/tap/ibazel
```

or with npm:

```bash
npm install @bazel/ibazel
```

Now just run our app with:

```bash
ibazel run src/main/play/helloworld
```

Navigate to `http://127.0.0.1:9000/greet`

And change `Hello` to `Greetings` in `src/main/closure/templates/greeter.soy`:

```js
{namespace templates.soy.greeter}

/**
 * Greets a person.
 */
{template .greet}
{@param name: string}
<p>
    Greetings <b>{$name}</b>!
{/template}
```

Look in your terminal, ibazel should detect changes and start reload process.
Once done, navigate to `http://127.0.0.1:9000/greet` again, and voila!
