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
