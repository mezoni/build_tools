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
