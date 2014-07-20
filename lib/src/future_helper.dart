part of build_tools;

class _FutureHelper {
  static Future forEach(Iterable iterable, Future<bool> action(current)) {
    var completer = new Completer();
    Future future;
    Iterator iterator;
    Function moveNext;
    var state = 0;
    var stop = false;
    moveNext = () {
      try {
        while (true) {
          switch (state) {
            case 0:
              iterator = iterable.iterator;
              state = 1;
              break;
            case 1:
              if (!iterator.moveNext()) {
                state = 2;
                break;
              }

              action(iterator.current).then((result) {
                if (result == false) {
                  completer.complete();
                } else {
                  state = 1;
                  Timer.run(moveNext);
                }
              }).catchError((e, s) {
                completer.completeError(e, s);
              });

              return;
            case 2:
              completer.complete();
              return;
          }
        }
      } catch (e, s) {
        completer.completeError(e, s);
      }
    };

    Timer.run(moveNext);
    return completer.future;
  }
}
