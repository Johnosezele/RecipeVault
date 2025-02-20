import 'package:equatable/equatable.dart';

/// Base class for all failures in the application.
/// Extends [Equatable] to allow comparison in tests.
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Represents failures that occur during server interactions.
class ServerFailure extends Failure {
  final int statusCode;

  const ServerFailure({
    required String message,
    required this.statusCode,
  }) : super(
          message: message,
          code: statusCode,
        );

  @override
  List<Object?> get props => [...super.props, statusCode];
}

/// Represents failures due to network connectivity issues.
class ConnectionFailure extends Failure {
  const ConnectionFailure({
    String message = 'No internet connection',
  }) : super(message: message, code: -1);
}

/// Represents failures that occur during local data operations.
class CacheFailure extends Failure {
  final String operation;

  const CacheFailure({
    required String message,
    required this.operation,
  }) : super(message: message, code: -2);

  @override
  List<Object?> get props => [...super.props, operation];
}

/// Represents failures that occur during data parsing.
class ParseFailure extends Failure {
  final String key;
  final Type expectedType;

  const ParseFailure({
    required String message,
    required this.key,
    required this.expectedType,
  }) : super(message: message, code: -3);

  @override
  List<Object?> get props => [...super.props, key, expectedType];
}

/// Represents failures that occur during input validation.
class ValidationFailure extends Failure {
  final String field;
  final String constraint;

  const ValidationFailure({
    required String message,
    required this.field,
    required this.constraint,
  }) : super(message: message, code: -4);

  @override
  List<Object?> get props => [...super.props, field, constraint];
}

/// Represents failures that occur due to invalid state transitions.
class StateFailure extends Failure {
  final String currentState;
  final String attemptedAction;

  const StateFailure({
    required String message,
    required this.currentState,
    required this.attemptedAction,
  }) : super(message: message, code: -5);

  @override
  List<Object?> get props => [...super.props, currentState, attemptedAction];
}