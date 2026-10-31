class EnvConfig {
  static const String keycloakUrl = String.fromEnvironment(
    'KEYCLOAK_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const String keycloakRealm = String.fromEnvironment(
    'KEYCLOAK_REALM',
    defaultValue: 'passon-ride',
  );

  static const String keycloakClientId = String.fromEnvironment(
    'KEYCLOAK_CLIENT_ID',
    defaultValue: 'passon-ride-app',
  );

  static const String keycloakClientSecret = String.fromEnvironment(
    'KEYCLOAK_CLIENT_SECRET',
    defaultValue: '',
  );

  static const String inngestEventKey = String.fromEnvironment(
    'INNGEST_EVENT_KEY',
    defaultValue: '',
  );

  static const String inngestSigningKey = String.fromEnvironment(
    'INNGEST_SIGNING_KEY',
    defaultValue: '',
  );
}
