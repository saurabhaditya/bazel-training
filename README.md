
# Flare Bazel Training Labs

## Initial Installation

Setup is currently supported on Mac-OSX or Linux.

```
scripts/setup
```

## IDEA/Bazel Integration

### Initial Import

Choose the "Import projectview" option when navigating through the "Import Bazel Project..." wizard in Jetbrains IDEs, and import project/.bazelproject. 

### Sharing Changes

Changes to .ijwb/.bazelproject are ignored; to share IDEA Bazel Plugin config with the team, edit project/.bazelproject and commit.

## Visual Studio Code Integration

Visual Studio Code has a first-class integration with Bazel, with some additional extensions that intelligently help with writing Bazel Build files. 

Below is a screenshot of this project loaded in VSCode with the Bazel support enabled, as well as the "Rainbow CSV" extension. You can see that in the Terminal the Bazel command ran and was successful.

![screenshot](doc/img/vscode-screenshot.png)

#### In Depth

There are detailed instructions in the provided with this repo file "VSCode" [README](https://github.com/flarebuild/training-labs/blob/master/.vscode/README.md) file. Alternatively, you can follow the short version in the next section.

#### Quick VSCode Install Steps

 1. Download VSCode, install it and run it.
 2. Press ⇧⌘P (Command-Shift-P) to bring up the "Show All Commands" drop down, and search for "code". 
 3. Select `Shell Command: Install 'code' in your PATH` and press ENTER.
 4. Then, in Terminal, cd to the project's root, and:

```
cd .vscode
make install
cd -
```
