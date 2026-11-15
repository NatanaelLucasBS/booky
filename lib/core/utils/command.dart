import 'dart:async';
import 'package:flutter/foundation.dart';

/// Resultado encapsulado de uma operação assíncrona.
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok._;
  const factory Result.error(Exception error) = Error._;

  bool get isOk => this is Ok<T>;
  bool get isError => this is Error<T>;

  T? get asOk => isOk ? (this as Ok<T>).value : null;
  Exception? get asError => isError ? (this as Error<T>).error : null;
}

final class Ok<T> extends Result<T> {
  final T value;
  const Ok._(this.value);

  @override
  String toString() => 'Result.ok($value)';
}

final class Error<T> extends Result<T> {
  final Exception error;
  const Error._(this.error);

  @override
  String toString() => 'Result.error($error)';
}

/// Helper Command para ViewModels (Slide 18 da Aula 24 - Arquitetura Flutter).
/// Encapsula execução de ações com estados running, error e completed.
abstract class Command<T> extends ChangeNotifier {
  Command();

  bool _running = false;
  bool get running => _running;

  Result<T>? _result;
  Result<T>? get result => _result;

  bool get completed => _result is Ok;
  bool get error => _result is Error;

  void clearResult() {
    _result = null;
    notifyListeners();
  }

  Future<void> _execute(Future<Result<T>> Function() action) async {
    if (_running) return;
    _running = true;
    _result = null;
    notifyListeners();

    try {
      _result = await action();
    } on Exception catch (e) {
      _result = Result.error(e);
    } catch (e) {
      _result = Result.error(Exception(e.toString()));
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}

typedef CommandAction0<T> = Future<Result<T>> Function();

class Command0<T> extends Command<T> {
  final CommandAction0<T> _action;

  Command0(this._action);

  Future<void> execute() async {
    await _execute(() => _action());
  }
}

typedef CommandAction1<T, A> = Future<Result<T>> Function(A arg);

class Command1<T, A> extends Command<T> {
  final CommandAction1<T, A> _action;

  Command1(this._action);

  Future<void> execute(A arg) async {
    await _execute(() => _action(arg));
  }
}
