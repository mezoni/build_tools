build_tools
===========

Build tools is build automation tool.

Build tools includes libraries `build_tools` and `build_shell`.

The `build_tools` is a main library and used for specifying the targets, rules and files used in the project.

The `build_shell` library can be  used for working with your project from the command line shell.

You can use the `build_shell` or you can write your own shell or do not use any shells at all and build the project programmatically.

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
