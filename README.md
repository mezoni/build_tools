build_tools
===========

Build tools is a build automation tool with a built-in command line shell.

Build tools includes libraries `build_tools` and `build_shell`.

The `build_tools` is a main library and used for specifying the targets, rules and files used in the project.

The `build_shell` library can be  used for working with your project from the command line shell.

Without using the command line shell the configuration is performed directly in the source code.

[Example of usage `build_tools` for bulding the Dart VM C++ native extension.][native_extension_with_build_tools]

Short example:

```dart
import "dart:async";
import "dart:io";
import "package:build_tools/build_shell.dart";
import "package:build_tools/build_tools.dart";

Future main(List args) async {
  target("default", ["breakfast"], (t, args) {
    print("Very good!");
  });

  target("breakfast", ["eat sandwich", "drink coffee"], (t, args) {
    print(t.name);
  });

  target("drink coffee", ["make coffee"], (t, args) {
    print(t.name);
  });

  target("eat sandwich", ["make sandwich"], (t, args) {
    print(t.name);
  });

  target("make coffee", [], (t, args) {
    print(t.name);
  });

  target("make sandwich", ["take bread", "take sausage"], (t, args) {
    print(t.name);
  });

  target("take bread", [], (t, args) {
    print(t.name);
  });

  target("take sausage", [], (t, args) {
    print(t.name);
  });

  exit(await new BuildShell().run(args));
}
```

Output:

```
take bread
take sausage
make sandwich
eat sandwich
make coffee
drink coffee
breakfast
Very good!
```

Short list of features:

**Targets (tasks)**

The targets describes the tasks and their dependencies (sources).

```dart
target("build", ["compile", "link"], (Target t, Map args) {
  // build after compile and link  
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
  // compile %.cc => %.obj 
});
```

```dart
rules(["%.html", "%.htm"], ["%.md"], (Target t, Map args) {
  // transform %.html => %.md
  // transform %.htm => %.md
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
exit(await new BuildShell().run(args));
```

[native_extension_with_build_tools]: https://github.com/mezoni/native_extension_with_build_tools
