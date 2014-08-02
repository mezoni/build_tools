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
void files(Iterable<String> names, Iterable<String> sources, TargetAction
    action) {
  for (var name in names) {
    file(name, sources, action);
  }
}

class FileTarget extends Target {
  FileTarget(String name, {TargetAction action, Iterable<String> sources}) :
      super(name, action: action, sources: sources) {
  }

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
  Future<int> rebuild([Map<String, dynamic> arguments]) {
    return new Future<int>(() {
      var builder = Builder.current;
      var exitCode = 0;
      return executeActions(actionsBefore, arguments).then((int exitCode) {
        if (exitCode != 0) {
          return exitCode;
        }

        return _FutureHelper.forEach(sources, (String source) {
          return new Future<bool>(() {
            var target = builder.resolveTarget(source);
            if (target != null) {
              return target.build().then((int result) {
                if (result != 0) {
                  // Break loop.
                  exitCode = result;
                  return false;
                }
              });
            }

            if (!FileUtils.testfile(source, "exists")) {
              logError("Source not found: $source");
              exitCode = -1;
              // Break loop.
              return false;
            }
          });
        }).then((result) {
          if (exitCode != 0) {
            return exitCode;
          }

          return executeActions(actions, arguments).then((int exitCode) {
            if (exitCode != 0) {
              return exitCode;
            }

            return executeActions(actionsAfter, arguments);
          });
        });
      });
    });
  }
}
