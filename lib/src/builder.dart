part of build_tools;

/**
 * Target builder.
 */
class Builder {
  /**
   * Current builder.
   */
  static final Builder current = new Builder();

  /**
   * Arguments of the main target.
   */
  Map<String, dynamic> arguments = <String, dynamic> {};

  /**
   * Default target name.
   */
  String defaultTarget = "default";

  /**
   * Last error message.
   */
  String lastError;

  /**
   * Trace logger.
   */
  Logger logger = new Logger("Builder");

  /**
   * Date of the build script.
   */
  DateTime scriptDate;

  /**
   * Trace flag.
   */
  bool trace = false;

  List<Rule> _rules = new List<Rule>();

  Map<String, Target> _targets = new Map<String, Target>();

  bool _scheduled = false;

  /**
   * Returns the rules.
   */
  Iterable<Rule> get rules {
    return new UnmodifiableListView<Rule>(_rules);
  }

  /**
   * Returns the read-only map of targets.
   */
  Map<String, Target> get targets {
    return new UnmodifiableMapView<String, Target>(_targets);
  }

  /**
   * Adds the rule.
   */
  void addRule(Rule rule) {
    if (rule == null) {
      throw new ArgumentError("rule: $rule");
    }

    _rules.add(rule);
  }

  /**
   * Adds the target.
   */
  void addTarget(Target target) {
    if (target == null) {
      throw new ArgumentError("target: $target");
    }

    var name = target.name;
    if (_targets.containsKey(name)) {
      logInfo("Target redefinition: '$name'");
    }

    _targets[target.name] = target;
  }

  /**
   * Builds the target.
   */
  Future<int> build(String name, {Map<String, dynamic> arguments}) {
    return new Future<int>(() {
      lastError = null;
      if (trace) {
        logger.onRecord.listen((LogRecord rec) {
          print('[${rec.level.name}] ${rec.message}');
        });
      }

      if (name == null) {
        name = defaultTarget;
      }

      if (name == null) {
        logError("Target not specified");
        return -1;
      }

      var target = resolveTarget(name);
      if (target == null) {
        logError("Target not found: $name");
        return -1;
      }

      return target.build(arguments);
    });
  }

  /**
   * Logs the error message.
   */
  void logError(String message) {
    lastError = message;
    logger.severe(message);
  }

  /**
   * Logs the information message.
   */
  void logInfo(String message) {
    logger.info(message);
  }

  /**
   * Resolves the target and returns the found or generated  (by the appropriate
   * rule) target; otherwise null.
   */
  Target resolveTarget(String name) {
    if (name == null) {
      throw new ArgumentError("name: $name");
    }

    var target = _targets[name];
    if (target != null) {
      return target;
    }

    for (var rule in _rules) {
      if (rule.canApply(name)) {
        logInfo("Generating target: '$name' ($rule)");
        var sources = rule.apply(name);
        target = new FileTarget(name, action: rule.action, sources: sources);
        _targets[name] = target;
        break;
      }
    }

    return target;
  }
}
