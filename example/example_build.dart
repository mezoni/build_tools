import "dart:io";
import "package:build_tools/build_tools.dart";
import "package:file_utils/file_utils.dart";

void main() {
  const String FILELIST = "packages.txt";
  var root = FileUtils.fullpath("..");
  var packages = FileUtils.glob(root + "/packages/**/*.dart");

  file(FILELIST, packages, (Target t, Map args) async {
    var files = t.sources;
    files = files.map((e) => e.replaceFirst(root + "/", ""));
    files = files.join("\n");
    await new File(t.name).writeAsString(files);
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
