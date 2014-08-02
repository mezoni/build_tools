build_tools
===========

Build tools is a build automation tool with a built-in command line shell.

Build tools includes libraries `build_tools` and `build_shell`.

The `build_tools` is a main library and used for specifying the targets, rules and files used in the project.

The `build_shell` library can be  used for working with your project from the command line shell.

Without using the command line shell the configuration is performed directly in the source code.

Example of the simple build script.

```dart
import "dart:io";
import "package:build_tools/build_tools.dart";
import "package:file_utils/file_utils.dart";

void main() {
  const String FILELIST = "packages.txt";
  var root = FileUtils.fullpath("..");
  var packages = FileUtils.glob(root + "/packages/**/*.dart");

  file(FILELIST, packages, (Target t, Map args) {
    var files = t.sources;
    files = files.map((e) => e.replaceFirst(root + "/", ""));
    files = files.join("\n");
    new File(t.name).writeAsStringSync(files);
  });

  target("default", [FILELIST], (Target t, Map args) {
    print("All done.");
  }, description: "Create list of Dart files used in packages");

  var builder = Builder.current;
  // Take into account modification date of this script.
  builder.scriptDate = FileStat.statSync(Platform.script.toFilePath()).modified;
  builder.trace = true;
  builder.build("default");
}
```

Example of the same script but with usage the built-in command shell.

``` dart
import "dart:io";
import "package:build_tools/build_shell.dart";
import "package:build_tools/build_tools.dart";
import "package:file_utils/file_utils.dart";

void main(List<String> args) {
  const String FILELIST = "packages.txt";
  var root = FileUtils.fullpath("..");
  var packages = FileUtils.glob(root + "/packages/**/*.dart");

  file(FILELIST, packages, (Target t, Map args) {
    var files = t.sources;
    files = files.map((e) => e.replaceFirst(root + "/", ""));
    files = files.join("\n");
    new File(t.name).writeAsStringSync(files);
  });

  target("default", [FILELIST], (Target t, Map args) {
    print("All done.");
  }, description: "Create list of Dart files used in packages");

  new BuildShell().run(args).then((exitCode) => exit(exitCode));
}
```

[Example of usage `build_tools` for bulding the Dart VM C++ native extension.][native_extension_with_build_tools]

Short list of features:

**Targets (tasks)**

The targets describes the tasks and their dependencies (sources).

```dart
target("build", ["compile", "link"], (Target t, Map args) {
  // build  
});
```

Both types of target actions supported, synchronous and asynchronous.

```dart
target("build", ["compile", "link"], (Target t, Map args) {
  // failed
  return new Future.value(-1);
}, description: "Build project", reusable: true);
```

**File targets**

The file targets automatically generates the targets for files.

These targets executed only when files are out of date or does not exists.

```dart
file("hello.obj", ["hello.c"], (Target t, Map args) {
  // compile
});
```

**Directory targets**

The directory targets automatically generates the targets for directories.

These targets perform a single task, they create a directories.

```dart
directory("dist");
```

```dart
directories(["dist, "temp"]);
```

**Rules**

The rules automatically generates the targets by specified patterns.

```dart
rule("%.o", ["%.cc"], (Target t, Map args) {
  // compile
});
```

```dart
rules(["%.html", "%.htm"], ["%.md"], (Target t, Map args) {
  // transform
});
```

**Hooks**

The hooks allows specifying the target actions that will be performed `before` or `after` target actions.

```dart
after(["git:commit"], (Target t, Map args) {
  // action
});
```

```dart
before(["compile", "link"], (Target t, Map args) {
  // action
});
```

**Build shell**

The built-in `build shell` allows use the build scripts as command line scripts.

```dart
new BuildShell().run(args).then((exitCode) => exit(exitCode));
```

[native_extension_with_build_tools]: https://github.com/mezoni/native_extension_with_build_tools
