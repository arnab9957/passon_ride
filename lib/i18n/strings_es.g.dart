///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsEs extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEs({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.es,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <es>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsEs _root = this; // ignore: unused_field

	@override 
	TranslationsEs $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEs(meta: meta ?? this.$meta);

	// Translations
	@override String get appName => 'PassionRide';
	@override late final _Translations$nav$es nav = _Translations$nav$es._(_root);
	@override late final _Translations$home$es home = _Translations$home$es._(_root);
	@override late final _Translations$search$es search = _Translations$search$es._(_root);
	@override late final _Translations$vehicle$es vehicle = _Translations$vehicle$es._(_root);
	@override late final _Translations$tours$es tours = _Translations$tours$es._(_root);
	@override late final _Translations$booking$es booking = _Translations$booking$es._(_root);
	@override late final _Translations$provider$es provider = _Translations$provider$es._(_root);
	@override late final _Translations$profile$es profile = _Translations$profile$es._(_root);
	@override late final _Translations$telematics$es telematics = _Translations$telematics$es._(_root);
	@override late final _Translations$documents$es documents = _Translations$documents$es._(_root);
	@override late final _Translations$common$es common = _Translations$common$es._(_root);
}

// Path: nav
class _Translations$nav$es extends Translations$nav$en {
	_Translations$nav$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get home => 'Inicio';
	@override String get rides => 'Viajes';
	@override String get wallet => 'Billetera';
	@override String get provider => 'Proveedor';
	@override String get profile => 'Perfil';
	@override String get search => 'Buscar';
	@override String get bookings => 'Reservas';
	@override String get chat => 'Chat';
	@override String get inbox => 'Bandeja de entrada';
	@override String get saved => 'Guardados';
	@override String get host => 'Anfitrión';
	@override String get earnings => 'Ganancias';
}

// Path: home
class _Translations$home$es extends Translations$home$en {
	_Translations$home$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get heroTag => 'MERCADO CINETICO P2P';
	@override String get heroTitle => 'Encuentra tu próximo viaje o únete a un tour guiado';
	@override String get searchPlaceholder => 'Buscar ciudad, modelo o destino...';
	@override String get exploreVehicles => 'Explorar Vehículos';
	@override String get guidedTours => 'Tours Guiados en Grupo';
	@override String get featuredRides => 'Alquiler de Vehículos Destacados';
	@override String get popularTours => 'Expediciones Guiadas Populares';
	@override String get trustMarketplace => 'Confianza Cinética y Anfitriones Verificados';
	@override String get viewAll => 'Ver Todo';
	@override String get nearYou => 'Cerca de Tu Ubicación';
	@override String get perDay => '/ día';
	@override String get perPerson => '/ persona';
}

// Path: search
class _Translations$search$es extends Translations$search$en {
	_Translations$search$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Descubrir Vehículos y Tours';
	@override String get filter => 'Filtrar';
	@override String get location => 'Ubicación';
	@override String get priceRange => 'Rango de Precios';
	@override String get vehicleType => 'Tipo de Vehículo';
	@override String get allTypes => 'Todos los Tipos';
	@override String get cars => 'Coches';
	@override String get bikes => 'Bicicletas y Motos';
	@override String get scooters => 'Scooters y Vehículos Eléctricos';
	@override String get tours => 'Tours Guiados';
	@override String get resultsFound => 'Resultados Encontrados';
	@override String get noResults => 'Ningún resultado coincide con tu filtro';
	@override String get resetFilters => 'Restablecer Filtros';
}

// Path: vehicle
class _Translations$vehicle$es extends Translations$vehicle$en {
	_Translations$vehicle$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get details => 'Detalles del Vehículo';
	@override String get specs => 'Especificaciones';
	@override String get pricePerDay => 'Precio por Día';
	@override String get bookNow => 'Reservar Ahora';
	@override String get keylessUnlock => 'Desbloqueo IoT sin Llave Incluido';
	@override String get features => 'Características del Vehículo';
	@override String get hostInfo => 'Información del Anfitrión';
	@override String get locationMap => 'Ubicación de Recogida y Entrega';
	@override String get reviews => 'Reseñas y Calificaciones de Conductores';
	@override String get rating => 'Calificación';
	@override String get transmission => 'Transmisión';
	@override String get fuelType => 'Combustible / Tipo EV';
	@override String get seats => 'Asientos';
}

// Path: tours
class _Translations$tours$es extends Translations$tours$en {
	_Translations$tours$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get guidedTrip => 'Tour Guiado en Grupo';
	@override String get itinerary => 'Itinerario del Tour';
	@override String get duration => 'Duración';
	@override String get groupSize => 'Tamaño Máximo del Grupo';
	@override String get includedServices => 'Servicios Incluidos';
	@override String get joinTour => 'Unirse a la Expedición';
	@override String get hostGuide => 'Líder / Guía del Tour';
	@override String get highlights => 'Puntos Destacados del Viaje';
	@override String get departureDate => 'Fecha de Salida';
	@override String get meetingPoint => 'Punto de Encuentro';
}

// Path: booking
class _Translations$booking$es extends Translations$booking$en {
	_Translations$booking$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get verification => 'Verificación de Reserva y PIN';
	@override String get checkout => 'Pagar Reserva';
	@override String get payment => 'Completar Pago';
	@override String get totalAmount => 'Monto Total';
	@override String get payWithRazorpay => 'Pagar con Razorpay / UPI';
	@override String get pinVerification => 'Verificar PIN de Alquiler';
	@override String get confirmBooking => 'Confirmar y Reservar';
	@override String get success => '¡Reserva Confirmada con Éxito!';
	@override String get status => 'Estado de la Reserva';
	@override String get active => 'Activa';
	@override String get completed => 'Completada';
	@override String get cancelled => 'Cancelada';
}

// Path: provider
class _Translations$provider$es extends Translations$provider$en {
	_Translations$provider$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get fleetDashboard => 'Panel de Control de Flota';
	@override String get earnings => 'Ganancias Financieras';
	@override String get addVehicle => 'Registrar Nuevo Vehículo';
	@override String get addTour => 'Publicar Tour Guiado';
	@override String get registerListing => 'Registrar Anuncio';
	@override String get activeListings => 'Vehículos Activos en Flota';
	@override String get monthlyRevenue => 'Ingresos Mensuales';
	@override String get manageFleet => 'Gestionar Anuncios';
}

// Path: profile
class _Translations$profile$es extends Translations$profile$en {
	_Translations$profile$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Mi Perfil';
	@override String get personalInfo => 'Información Personal';
	@override String get vehicleInfo => 'Detalles del Vehículo';
	@override String get driverLicense => 'Licencia de Conducir';
	@override String get language => 'Idioma de la aplicación';
	@override String get settings => 'Configuración';
	@override String get logout => 'Cerrar sesión';
	@override String get editProfile => 'Editar Perfil';
	@override String get verified => 'Verificado';
	@override String get accountPreferences => 'Cuenta y Preferencias';
	@override String get darkMode => 'Modo Oscuro';
	@override String get darkModeSubtitle => 'Alternar tema oscuro o claro';
	@override String get documents => 'Documentos y Licencias';
	@override String get documentsSubtitle => 'Licencia de conducir, tarjeta Aadhar y DNI';
	@override String get trustReputation => 'Reputación de Confianza Cinética';
	@override String get trustReputationSubtitle => 'Ver desglose de puntuación de confianza';
	@override String get passwordReset => 'Restablecer Contraseña';
	@override String get passwordResetSubtitle => 'Enviar correo de restablecimiento de contraseña';
	@override String get financials => 'Finanzas del Proveedor';
	@override String get financialsSubtitle => 'Ganancias, pagos e información bancaria';
	@override String get aiGenerator => 'Generador de Tours IA';
	@override String get aiGeneratorSubtitle => 'Crear itinerario con Co-Pilot IA';
	@override String get inAppPortal => 'Portal Web Integrado';
	@override String get inAppPortalSubtitle => 'Incrustar y ver cualquier sitio web externo';
	@override String get feedback => 'Enviar Comentarios de la App';
	@override String get feedbackSubtitle => 'Enviar reseña de la app o reportar errores';
	@override String get feedbackInsights => 'Estadísticas de Comentarios y Confianza';
	@override String get feedbackInsightsSubtitle => 'Ver analítica de reseñas y sentimiento IA';
	@override String get switchRole => 'Cambiar Rol';
}

// Path: telematics
class _Translations$telematics$es extends Translations$telematics$en {
	_Translations$telematics$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get ioTHub => 'Centro de Telemática de Vehículos';
	@override String get remoteLock => 'Bloqueo / Desbloqueo Remoto';
	@override String get engineStatus => 'Estado del Motor';
	@override String get batteryLevel => 'Nivel de Batería';
	@override String get gpsTracking => 'Rastreo GPS en Vivo';
	@override String get speedAlert => 'Alerta de Velocidad';
}

// Path: documents
class _Translations$documents$es extends Translations$documents$en {
	_Translations$documents$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get identityVerification => 'Verificación de Identidad';
	@override String get driverLicense => 'Licencia de Conducir';
	@override String get governmentId => 'Identificación Oficial';
	@override String get complianceStatus => 'Estado de Cumplimiento';
	@override String get uploadDoc => 'Subir Documento';
}

// Path: common
class _Translations$common$es extends Translations$common$en {
	_Translations$common$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get welcome => '¡Bienvenido de nuevo!';
	@override String get search => 'Buscar...';
	@override String get cancel => 'Cancelar';
	@override String get save => 'Guardar';
	@override String get confirm => 'Confirmar';
	@override String get loading => 'Cargando...';
	@override String get error => 'Algo salió mal';
	@override String get selectLanguage => 'Seleccionar Idioma';
	@override String get nativeLanguage => 'Idioma Nativo';
	@override String get dynamicTranslation => 'Traduciendo contenido...';
	@override String get close => 'Cerrar';
	@override String get back => 'Atrás';
	@override String get details => 'Detalles';
	@override String get status => 'Estado';
	@override String get view => 'Ver';
	@override String get submit => 'Enviar';
}

/// The flat map containing all translations for locale <es>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEs {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appName' => 'PassionRide',
			'nav.home' => 'Inicio',
			'nav.rides' => 'Viajes',
			'nav.wallet' => 'Billetera',
			'nav.provider' => 'Proveedor',
			'nav.profile' => 'Perfil',
			'nav.search' => 'Buscar',
			'nav.bookings' => 'Reservas',
			'nav.chat' => 'Chat',
			'nav.inbox' => 'Bandeja de entrada',
			'nav.saved' => 'Guardados',
			'nav.host' => 'Anfitrión',
			'nav.earnings' => 'Ganancias',
			'home.heroTag' => 'MERCADO CINETICO P2P',
			'home.heroTitle' => 'Encuentra tu próximo viaje o únete a un tour guiado',
			'home.searchPlaceholder' => 'Buscar ciudad, modelo o destino...',
			'home.exploreVehicles' => 'Explorar Vehículos',
			'home.guidedTours' => 'Tours Guiados en Grupo',
			'home.featuredRides' => 'Alquiler de Vehículos Destacados',
			'home.popularTours' => 'Expediciones Guiadas Populares',
			'home.trustMarketplace' => 'Confianza Cinética y Anfitriones Verificados',
			'home.viewAll' => 'Ver Todo',
			'home.nearYou' => 'Cerca de Tu Ubicación',
			'home.perDay' => '/ día',
			'home.perPerson' => '/ persona',
			'search.title' => 'Descubrir Vehículos y Tours',
			'search.filter' => 'Filtrar',
			'search.location' => 'Ubicación',
			'search.priceRange' => 'Rango de Precios',
			'search.vehicleType' => 'Tipo de Vehículo',
			'search.allTypes' => 'Todos los Tipos',
			'search.cars' => 'Coches',
			'search.bikes' => 'Bicicletas y Motos',
			'search.scooters' => 'Scooters y Vehículos Eléctricos',
			'search.tours' => 'Tours Guiados',
			'search.resultsFound' => 'Resultados Encontrados',
			'search.noResults' => 'Ningún resultado coincide con tu filtro',
			'search.resetFilters' => 'Restablecer Filtros',
			'vehicle.details' => 'Detalles del Vehículo',
			'vehicle.specs' => 'Especificaciones',
			'vehicle.pricePerDay' => 'Precio por Día',
			'vehicle.bookNow' => 'Reservar Ahora',
			'vehicle.keylessUnlock' => 'Desbloqueo IoT sin Llave Incluido',
			'vehicle.features' => 'Características del Vehículo',
			'vehicle.hostInfo' => 'Información del Anfitrión',
			'vehicle.locationMap' => 'Ubicación de Recogida y Entrega',
			'vehicle.reviews' => 'Reseñas y Calificaciones de Conductores',
			'vehicle.rating' => 'Calificación',
			'vehicle.transmission' => 'Transmisión',
			'vehicle.fuelType' => 'Combustible / Tipo EV',
			'vehicle.seats' => 'Asientos',
			'tours.guidedTrip' => 'Tour Guiado en Grupo',
			'tours.itinerary' => 'Itinerario del Tour',
			'tours.duration' => 'Duración',
			'tours.groupSize' => 'Tamaño Máximo del Grupo',
			'tours.includedServices' => 'Servicios Incluidos',
			'tours.joinTour' => 'Unirse a la Expedición',
			'tours.hostGuide' => 'Líder / Guía del Tour',
			'tours.highlights' => 'Puntos Destacados del Viaje',
			'tours.departureDate' => 'Fecha de Salida',
			'tours.meetingPoint' => 'Punto de Encuentro',
			'booking.verification' => 'Verificación de Reserva y PIN',
			'booking.checkout' => 'Pagar Reserva',
			'booking.payment' => 'Completar Pago',
			'booking.totalAmount' => 'Monto Total',
			'booking.payWithRazorpay' => 'Pagar con Razorpay / UPI',
			'booking.pinVerification' => 'Verificar PIN de Alquiler',
			'booking.confirmBooking' => 'Confirmar y Reservar',
			'booking.success' => '¡Reserva Confirmada con Éxito!',
			'booking.status' => 'Estado de la Reserva',
			'booking.active' => 'Activa',
			'booking.completed' => 'Completada',
			'booking.cancelled' => 'Cancelada',
			'provider.fleetDashboard' => 'Panel de Control de Flota',
			'provider.earnings' => 'Ganancias Financieras',
			'provider.addVehicle' => 'Registrar Nuevo Vehículo',
			'provider.addTour' => 'Publicar Tour Guiado',
			'provider.registerListing' => 'Registrar Anuncio',
			'provider.activeListings' => 'Vehículos Activos en Flota',
			'provider.monthlyRevenue' => 'Ingresos Mensuales',
			'provider.manageFleet' => 'Gestionar Anuncios',
			'profile.title' => 'Mi Perfil',
			'profile.personalInfo' => 'Información Personal',
			'profile.vehicleInfo' => 'Detalles del Vehículo',
			'profile.driverLicense' => 'Licencia de Conducir',
			'profile.language' => 'Idioma de la aplicación',
			'profile.settings' => 'Configuración',
			'profile.logout' => 'Cerrar sesión',
			'profile.editProfile' => 'Editar Perfil',
			'profile.verified' => 'Verificado',
			'profile.accountPreferences' => 'Cuenta y Preferencias',
			'profile.darkMode' => 'Modo Oscuro',
			'profile.darkModeSubtitle' => 'Alternar tema oscuro o claro',
			'profile.documents' => 'Documentos y Licencias',
			'profile.documentsSubtitle' => 'Licencia de conducir, tarjeta Aadhar y DNI',
			'profile.trustReputation' => 'Reputación de Confianza Cinética',
			'profile.trustReputationSubtitle' => 'Ver desglose de puntuación de confianza',
			'profile.passwordReset' => 'Restablecer Contraseña',
			'profile.passwordResetSubtitle' => 'Enviar correo de restablecimiento de contraseña',
			'profile.financials' => 'Finanzas del Proveedor',
			'profile.financialsSubtitle' => 'Ganancias, pagos e información bancaria',
			'profile.aiGenerator' => 'Generador de Tours IA',
			'profile.aiGeneratorSubtitle' => 'Crear itinerario con Co-Pilot IA',
			'profile.inAppPortal' => 'Portal Web Integrado',
			'profile.inAppPortalSubtitle' => 'Incrustar y ver cualquier sitio web externo',
			'profile.feedback' => 'Enviar Comentarios de la App',
			'profile.feedbackSubtitle' => 'Enviar reseña de la app o reportar errores',
			'profile.feedbackInsights' => 'Estadísticas de Comentarios y Confianza',
			'profile.feedbackInsightsSubtitle' => 'Ver analítica de reseñas y sentimiento IA',
			'profile.switchRole' => 'Cambiar Rol',
			'telematics.ioTHub' => 'Centro de Telemática de Vehículos',
			'telematics.remoteLock' => 'Bloqueo / Desbloqueo Remoto',
			'telematics.engineStatus' => 'Estado del Motor',
			'telematics.batteryLevel' => 'Nivel de Batería',
			'telematics.gpsTracking' => 'Rastreo GPS en Vivo',
			'telematics.speedAlert' => 'Alerta de Velocidad',
			'documents.identityVerification' => 'Verificación de Identidad',
			'documents.driverLicense' => 'Licencia de Conducir',
			'documents.governmentId' => 'Identificación Oficial',
			'documents.complianceStatus' => 'Estado de Cumplimiento',
			'documents.uploadDoc' => 'Subir Documento',
			'common.welcome' => '¡Bienvenido de nuevo!',
			'common.search' => 'Buscar...',
			'common.cancel' => 'Cancelar',
			'common.save' => 'Guardar',
			'common.confirm' => 'Confirmar',
			'common.loading' => 'Cargando...',
			'common.error' => 'Algo salió mal',
			'common.selectLanguage' => 'Seleccionar Idioma',
			'common.nativeLanguage' => 'Idioma Nativo',
			'common.dynamicTranslation' => 'Traduciendo contenido...',
			'common.close' => 'Cerrar',
			'common.back' => 'Atrás',
			'common.details' => 'Detalles',
			'common.status' => 'Estado',
			'common.view' => 'Ver',
			'common.submit' => 'Enviar',
			_ => null,
		};
	}
}
