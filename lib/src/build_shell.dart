part of build_utils.build_shell;

/**
 * Build shell.
 */
class BuildShell {
  ArgParser _argParser;
  Map<String, dynamic> _arguments;
  int _exitCode;
  String _targetName;

  /**
   * Runs the build shell, builds the target and returns exit code.
   */
  Future<int> run(List<String> arguments) {
    return _run(arguments);
  }

  Future<int> _build(String name, Map arguments) async {
    var builder = Builder.current;
    var script = Platform.script.toFilePath();
    builder.scriptDate = FileStat.statSync(script).modified;
    int exitCode = await builder.build(name, arguments: arguments);
    if (exitCode != 0) {
      if (builder.lastError != null) {
        print(builder.lastError);
      }
    }

    return exitCode;
  }

  void _displayTargetList() {
    print("List of available targets:");
    var builder = Builder.current;
    var defaultIncluded = false;
    var defaultTarget = builder.defaultTarget;
    var targets = <List<String>>[];
    var maxLength = 0;
    for (var target in builder.targets.values) {
      if (target.description != null) {
        var name = target.name;
        targets.add([name, target.description]);
        var length = name.length;
        if (maxLength < length) {
          maxLength = length;
        }

        if (name == defaultTarget) {
          defaultIncluded = true;
        }
      }
    }

    if (!defaultIncluded) {
      var target = builder.targets[defaultTarget];
      if (target != null) {
        var description = target.description;
        var name = target.name;
        if (description == null) {
          description = "";
        }

        targets.add([name, description]);
        var length = name.length;
        if (maxLength < length) {
          maxLength = length;
        }
      }
    }

    targets.sort((a, b) => a[0].compareTo(b[0]));
    for (var target in targets) {
      var indent = "  ";
      var name = target[0];
      var description = target[1];
      var length = name.length;
      var pad = "".padRight(maxLength - length, " ");
      if (name == defaultTarget) {
        indent = indent.substring(0, indent.length - 1) + "*";
      }

      print("$indent$name$pad   $description");
    }
  }

  void _displayUsage() {
    var indent = "  ";
    var script = Platform.script.toFilePath();
    var usage = _argParser.usage.split("\n").join("\n$indent");
    script = FileUtils.basename(script);
    print("Usage: $script [options] target [arguments]");
    print("Options:");
    print("$indent$usage");
    print("Examples:");
    print("$indent$script");
    print("$indent$script --list");
    print("$indent$script --trace build");
    print("$indent$script --trace hello --name \"John Smith\"");
  }

  Future<int> _run(List<String> arguments) {
    return new Future<int>(() {
      _reset();
      if (!_parse(arguments)) {
        return _exitCode;
      }

      return _build(_targetName, _arguments);
    });
  }

  bool _parse(List<String> args) {
    _argParser = new ArgParser();
    _argParser.addFlag("list", help: "List available targets.", negatable: false
        );
    _argParser.addFlag("trace", help: "Trace building process.", negatable:
        false);

    ArgResults argResults;
    try {
      argResults = _argParser.parse(args);
    } on FormatException catch (e) {
      _displayUsage();
      _exitCode = -1;
      return false;
    }

    Builder.current.trace = argResults["trace"];
    if (argResults["list"]) {
      _displayTargetList();
      return false;
    }

    var rest = argResults.rest.toList();
    if (rest.isEmpty) {
      _targetName = "default";
      return true;
    }

    _targetName = rest.removeAt(0);
    while (true) {
      if (rest.length == 0) {
        break;
      }

      var key = rest.removeAt(0);
      if (!key.startsWith("--")) {
        _displayUsage();
        _exitCode = -1;
        return false;
      }

      key = key.substring(2);
      if (rest.length != 0) {
        var value = rest[0];
        if (!value.startsWith("--")) {
          rest.removeAt(0);
          _arguments[key] = value;
        } else {
          _arguments[key] = null;
        }
      } else {
        _arguments[key] = null;
      }
    }

    return true;
  }

  void _reset() {
    _arguments = <String, dynamic> {};
    _exitCode = 0;
    _targetName = null;
  }
}
