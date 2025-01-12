import 'package:flutter/foundation.dart';
import 'dart:async';

class Debouncer {
  Debouncer({this.milliseconds = defaultDebounceMilliSeconds});

  static const defaultDebounceMilliSeconds = 100;
  final int milliseconds;
  Timer? _timer;

  void call(VoidCallback action) {
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void close() {
    _timer?.cancel();
    _timer = null;
  }
}


