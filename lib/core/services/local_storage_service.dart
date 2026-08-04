/// DEPRECATED: This service is no longer used for CRM data.
/// All data now comes from the Spring Boot REST API via [ApiService].
/// Only [TokenStorageService] is used for persisting the JWT session token.
///
/// This file is kept as a stub to avoid breaking any import that hasn't
/// been updated yet, but all methods are no-ops or throw.
@Deprecated(
  'Use ApiService for data operations and TokenStorageService for auth.',
)
class LocalStorageService {
  LocalStorageService._();

  static Future<void> init() async {
    // No-op: initialization is handled by TokenStorageService in main.dart
  }
}
