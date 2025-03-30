import 'package:meta/meta.dart';

/// A mixin that provides clone capability for objects.
///
/// Classes using this mixin must implement the [clone] method to provide
/// a way to create a deep copy of the object. This is useful for implementing
/// immutable objects or value objects that need copying functionality.
///
/// Example:
/// ```dart
/// class MyClass with ClonableMixin<MyClass> {
///   @override
///   MyClass clone() => MyClass();
/// }
/// ```
mixin ClonableMixin<T> {
  /// Creates a deep copy of the object.
  ///
  /// Returns a new instance of type [T] that is a copy of this object.
  @mustBeOverridden
  T clone();
}
