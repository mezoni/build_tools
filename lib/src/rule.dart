part of build_tools;

/**
 * Creates the rule.
 */
void rule(String target, Iterable<String> sources, TargetAction action) {
  var rule = new Rule(target, action: action, sources: sources);
  Builder.current.addRule(rule);
}

/**
 * Creates the rules.
 */
void rules(Iterable<String> targets, Iterable<String> sources, TargetAction
    action) {
  for (var target in targets) {
    rule(target, sources, action);
  }
}

class Rule {
  /**
   * Target action.
   */
  final TargetAction action;

  /**
   * Target name.
   */
  final String target;

  List<PatSubst> _patSubst;

  List<String> _sources;

  PatSubst _targetMatcher;

  Rule(this.target, {this.action, Iterable<String>
      sources}) {
    if (target == null) {
      throw new ArgumentError("target: $target");
    }

    _patSubst = <PatSubst>[];
    _sources = <String>[];
    _targetMatcher = new PatSubst(target, target);
    if (sources != null) {
      _sources.addAll(sources);
      for (var source in _sources) {
        var patSubst = new PatSubst(target, source);
        _patSubst.add(patSubst);
      }
    }
  }

  /**
   * Applies the rule and returns the transformed source names for the specified
   * target name.
   */
  Iterable<String> apply(String target) {
    var result = <String>[];
    for (var patSubst in _patSubst) {
      var source = patSubst.replace(target);
      result.add(source);
    }

    return result;
  }

  /**
   * Returns true if the rule can be applied to the target [name]; otherwise
   * false.
   */
  bool canApply(String name) {
    return _targetMatcher.replace(name) != null;
  }

  /**
   * Returns the string representation.
   */
  String toString() {
    var sb = new StringBuffer();
    sb.write("'$target' => ");
    var list = <String>[];
    for (var source in _sources) {
      list.add("'$source'");
    }

    sb.writeAll(list, ", ");
    return sb.toString();
  }
}
