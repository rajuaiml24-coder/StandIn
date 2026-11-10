import 'package:firebase_core/firebase_core.dart';

String actionError(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'This action was not allowed. Please try again or contact support.',
      'unauthenticated' => 'Please sign in again to continue.',
      'unavailable' ||
      'deadline-exceeded' =>
        'Connection unavailable. Please try again when you are online.',
      _ => 'This action could not be completed. Please try again.',
    };
  }
  if (error is StateError) return error.message.toString();
  if (error is ArgumentError) {
    return error.message?.toString() ?? 'Please check this value';
  }
  return 'This action could not be completed. Please try again.';
}
