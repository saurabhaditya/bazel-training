# Lab 8 - rules_closure

## Lab rules_closure.1 - Dependencies

Add this to `WORKSPACE` file to instantiate `rules_closure`:

```bazel
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
```

## Lab rules_closure.2 - closure js templates

Lets greet somebody.
First, create `soy` template, `src/main/closure/templates/greeter.soy`:

```javascript
{namespace templates.soy.greeter}

/**
* Greets a person.
*/
{template .greet}
{@param name: string}
<p>
    Hello <b>{$name}</b>!
{/template}
```

Then, build file for it, `src/main/closure/templates/BUILD.bazel`:

```bazel
load(
    "@io_bazel_rules_closure//closure:defs.bzl", 
    "closure_js_template_library",
)

closure_js_template_library(
    name = "greeter_soy",
    srcs = ["greeter.soy"],
)
```

And, lets see the output:

```bash
bazel build src/main/closure/templates:greeter_soy
cat bazel-bin/src/main/closure/templates/greeter.soy.js
```

Ok, but we want to greet somebody in html body.
So we should wrap `greeter_soy`,
with `src/main/closure/templates/greeter.js`:

```javascript
goog.provide('templates.Greeter');

goog.require('goog.soy');
goog.require('templates.soy.greeter');

/**
 * Greeter page.
 * @param {string} name Name of person to greet.
 * @constructor
 * @final
 */
templates.Greeter = function(name) {
/**
 * Name of person to greet.
 * @private {string}
 * @const
 */
this.name_ = name;
};

/**
 * Renders HTML greeting as document body.
 */
templates.Greeter.prototype.greet = function() {
goog.soy.renderElement(goog.global.document.body,
                        templates.soy.greeter.greet,
                        {name: this.name_});
};
```

It would not be superfluous to write a test next,
`src/main/closure/templates/greeter_test.js`:

```javascript
goog.require('goog.asserts');
goog.require('goog.testing.asserts');
goog.require('goog.testing.jsunit');
goog.require('templates.Greeter');

function testGreet() {
    var greeter = new templates.Greeter('Justine');
    greeter.greet();
    var body = document.body;
    goog.asserts.assert(body != null);
    assertHTMLEquals('<p>Hello <b>Justine</b>!', body.innerHTML);
}
```

We should update our build file now,
`src/main/closure/templates/BUILD.bazel`:

```bazel
load(
    "@io_bazel_rules_closure//closure:defs.bzl", 
    "closure_js_template_library",
    "closure_js_library",
    "closure_js_test",
)

closure_js_template_library(
    name = "greeter_soy",
    srcs = ["greeter.soy"],
)

closure_js_library(
    name = "greeter_lib",
    srcs = ["greeter.js"],
    deps = [
        ":greeter_soy",
        # soy support
        "@io_bazel_rules_closure//closure/library/soy",
    ],
    visibility = ["//visibility:public"],
)

closure_js_test(
    name = "greeter_test",
    timeout = "short",
    srcs = ["greeter_test.js"],
    deps = [
        ":greeter_lib",
        # testing libs suport
        "@io_bazel_rules_closure//closure/library/asserts",
        "@io_bazel_rules_closure//closure/library/testing:asserts",
        "@io_bazel_rules_closure//closure/library/testing:jsunit",
    ],
)
```

Now, test it:

```bash
bazel run src/main/closure/templates:greeter_test
```
