part of build_tools;

/**
 * Creates the target that creates the directory.
 */
void directory(String name) {
  file(name, [], (Target t, Map args) {
    FileUtils.mkdir([t.name], recursive: true);
  });
}

/**
 * Creates the targets that creates the directories.
 */
void directories(Iterable<String> names) {
  for (var name in names) {
    directory(name);
  }
}

/**
 * Creates the target which is responsible for creating the file.
 */
void file(String name, Iterable<String> sources, TargetAction action) {
  var target = new FileTarget(name, action: action, sources: sources);
  Builder.current.addTarget(target);
}

/**
 * Creates the targets which is responsible for creating the files.
 */
void files(Iterable<String> names, Iterable<String> sources, TargetAction action) {
  for (var name in names) {
    file(name, sources, action);
  }
}

class FileTarget extends Target {
  FileTarget(String name, {TargetAction action, Iterable<String> sources}) : super(name, action: action, sources: sources);

  /**
   * Returns the date of file; otherwise null.
   */
  DateTime get date {
    var stat = FileStat.statSync(name);
    if (stat.type == FileSystemEntityType.NOT_FOUND) {
      return null;
    }

    return stat.modified;
  }

  /**
   * Returns true if the file up to date; otherwise false.
   */
  bool get uptodate {
    var date = this.date;
    if (date == null) {
      return false;
    }

    var builder = Builder.current;
    if (!sources.isEmpty) {
      if (builder.scriptDate != null) {
        if (date.compareTo(builder.scriptDate) < 0) {
          return false;
        }
      }
    }

    for (var source in sources) {
      var target = builder.resolveTarget(source);
      if (target != null) {
        if (!target.uptodate) {
          return false;
        }

        if (target.date != null && date.compareTo(target.date) < 0) {
          return false;
        }
      } else {
        if (!FileUtils.uptodate(name, [source])) {
          return false;
        }
      }
    }

    return true;
  }

  /**
   * Rebuilds the target.
   */
  Future<int> rebuild([Map<String, dynamic> arguments]) async {
    var builder = Builder.current;
    if (_building) {
      logError("Recursive call of the target: '$name'");
      return -1;
    }

    _building = true;
    int exitCode = await executeActions(actionsBefore, arguments);
    if (exitCode != 0) {
      _building = false;
      return exitCode;
    }

    for (var source in sources) {
      var target = builder.resolveTarget(source);
      if (target != null) {
        exitCode = await target.build();
        if (exitCode != 0) {
          _building = false;
          return exitCode;
        }
      } else {
        if (!FileUtils.testfile(source, "exists")) {
          logError("Source not found: $source");
          _building = false;
          return exitCode = -1;
        }
      }
    }

    exitCode = await executeActions(actions, arguments);
    if (exitCode != 0) {
      _building = false;
      return exitCode;
    }

    exitCode = await executeActions(actionsAfter, arguments);
    _building = false;
    return exitCode;
  }
}
