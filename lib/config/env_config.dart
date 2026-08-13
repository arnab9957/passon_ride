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
    defaultValue: 'qxETlv4jm8M7ViBB8UGWO908QBqB9lAFKSVvnhff2_h-H_o85ZyRsd36ntk_waF_Bse5T05ed0dhmJHgapbbTg',
  );

  static const String inngestSigningKey = String.fromEnvironment(
    'INNGEST_SIGNING_KEY',
    defaultValue: 'signkey-prod-12dbb552b743667c5601ef1c27851b7970ecf708e32d41846702412cc3133503',
  );
}
