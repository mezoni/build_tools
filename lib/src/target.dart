part of build_tools;

/**
 * Adds the "after" action to specified targets.
 */
void after(List<String> targets, TargetAction action) {
  if (targets == null) {
    throw new ArgumentError("targets: $targets");
  }

  if (action == null) {
    throw new ArgumentError("action: $action");
  }

  var builder = Builder.current;
  for (var name in targets) {
    var target = builder.targets[name];
    if (target == null) {
      throw new ArgumentError("Target not found: $target");
    }

    target._actionsAfter.add(action);
  }
}

/**
 * Adds the "before" action to specified targets.
 */
void before(List<String> targets, TargetAction action) {
  if (targets == null) {
    throw new ArgumentError("targets: $targets");
  }

  if (action == null) {
    throw new ArgumentError("action: $action");
  }

  var builder = Builder.current;
  for (var name in targets) {
    var target = builder.targets[name];
    if (target == null) {
      throw new ArgumentError("Target not found: $target");
    }

    target._actionsBefore.add(action);
  }
}

/**
 * Creates the target.
 */
void target(String name, Iterable<String> sources, TargetAction action, {String description, bool reusable: false}) {
  var target = new Target(name, action: action, description: description, sources: sources, reusable: reusable);
  Builder.current.addTarget(target);
}

/**
 * Creates the targets.
 */
void targets(Iterable<String> names, Iterable<String> sources, TargetAction action, {String description, bool reusable: false}) {
  for (var name in names) {
    target(name, sources, action, description: description, reusable: reusable);
  }
}

class Target {
  static List<String> _targetQueue = <String>[];

  /**
   * Target [description]. If specified, the target will be displayed in the
   * list of available targets.
   */
  final String description;

  /**
   * Target [name].
   */
  final String name;

  List<TargetAction> _actions;

  List<TargetAction> _actionsAfter;

  List<TargetAction> _actionsBefore;

  bool _building;

  DateTime _date;

  bool _reusable;

  List<String> _sources;

  Target(this.name, {TargetAction action, this.description, Iterable<String> sources, bool reusable: false}) {
    if (name == null || name.isEmpty) {
      throw new ArgumentError("name: '$name'");
    }

    if (reusable == null) {
      throw new ArgumentError("reusable: '$reusable'");
    }

    _actions = <TargetAction>[];
    _actionsAfter = <TargetAction>[];
    _actionsBefore = <TargetAction>[];
    _sources = <String>[];
    _building = false;
    _reusable = reusable;
    if (action != null) {
      _actions.add(action);
    }

    if (sources != null) {
      _sources.addAll(sources);
    }
  }

  /**
   * Returns the actions.
   */
  Iterable<TargetAction> get actions {
    return new UnmodifiableListView<TargetAction>(_actions);
  }

  /**
   * Returns the "after" actions.
   */
  Iterable<TargetAction> get actionsAfter {
    return new UnmodifiableListView<TargetAction>(_actionsAfter);
  }

  /**
   * Returns the "before" actions.
   */
  Iterable<TargetAction> get actionsBefore {
    return new UnmodifiableListView<TargetAction>(_actionsBefore);
  }

  /**
   * Returns the date of target if available; otherwise null.
   */
  DateTime get date {
    return _date;
  }

  /**
   * Returns the targets sources.
   */
  Iterable<String> get sources {
    return new UnmodifiableListView<String>(_sources);
  }

  /**
   * Returns true if the target up to date; otherwise false.
   */
  bool get uptodate {
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

    for (var name in _sources) {
      var target = builder.resolveTarget(name);
      if (target == null) {
        return false;
      }

      if (!target.uptodate) {
        return false;
      }

      if (target.date != null) {
        if (date.compareTo(target.date) < 0) {
          return false;
        }
      }
    }

    return true;
  }

  /**
   * Builds the target if it out of date.
   */
  Future<int> build([Map<String, dynamic> arguments]) async {
    _logBeginBuild();
    if (uptodate) {
      _logUptodate();
      return 0;
    }

    int exitCode = await rebuild(arguments);
    _logEndBuild();
    return exitCode;
  }

  /**
   * Executes the target actions.
   */
  Future<int> executeActions(List<TargetAction> actions, Map<String, dynamic> arguments) async {
    if (arguments == null) {
      arguments = <String, dynamic>{};
    }

    for (var action in actions) {
      var exitCode = await action(this, arguments);
      if (exitCode is int && exitCode != 0) {
        logError("Target action failed ($exitCode): '$name'");
        return exitCode;
      }
    }

    return 0;
  }

  /**
   * Logs the error message.
   */
  void logError(String message) {
    Builder.current.logError(message);
  }

  /**
   * Logs the information message.
   */
  void logInfo(String message) {
    Builder.current.logInfo(message);
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
      if (target == null) {
        logError("Cannot resolve target: '$source'");
        _building = false;
        return -1;
      }

      exitCode = await target.build();
      if (exitCode != 0) {
        _building = false;
        return exitCode;
      }
    }

    exitCode = await executeActions(actions, arguments);
    if (exitCode != 0) {
      _building = false;
      return exitCode;
    }

    _date = new DateTime.now();
    exitCode = await executeActions(actionsAfter, arguments);
    if (exitCode != 0) {
      _building = false;
      return exitCode;
    }

    if (_reusable) {
      reset();
    }

    _building = false;
    return 0;
  }


  /**
   * Resets the target to initial state.
   */
  void reset() {
    _date = null;
  }

  /**
   * Returns the string representation.
   */
  String toString() {
    return name;
  }

  /**
     * Logs the beginning state of the target build.
     */
  void _logBeginBuild() {
    _targetQueue.add(name);
    logInfo("Begin build target: ${_targetQueueToPath()}");
  }

  /**
     * Logs the ending state of the target build.
     */
  void _logEndBuild() {
    logInfo("End build target: ${_targetQueueToPath()}");
    if (!_targetQueue.isEmpty) {
      _targetQueue.removeLast();
    }
  }

  /**
     * Logs the state when the target up to date.
     */
  void _logUptodate() {
    logInfo("Target up to date: '$name'");
  }

  static String _targetQueueToPath() {
    var sb = new StringBuffer();
    var list = <String>[];
    for (var target in _targetQueue) {
      list.add("'$target'");
    }

    sb.writeAll(list, " => ");
    return sb.toString();
  }
}
