import "dart:io";
import "package:build_tools/build_shell.dart";
import "package:build_tools/build_tools.dart";
import "package:file_utils/file_utils.dart";

void main(List<String> args) {
  const String FILELIST = "packages.txt";
  var root = FileUtils.getcwd();
  var files = FileUtils.glob(root + "/lib/**/*.dart");

  file(FILELIST, files, (Target t, Map args) async {
    var files = t.sources;
    files = files.map((e) => e.replaceFirst(root + "/", ""));
    var content = files.join("\n");
    await new File(t.name).writeAsString(content);
  });

  target("default", [FILELIST], (Target t, Map args) {
    print("All done.");
  }, description: "Create list of Dart files in lib directory");

  new BuildShell().run(args).then((exitCode) => exit(exitCode));
}
