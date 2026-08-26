///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations

	/// en: 'PassionRide'
	String get appName => 'PassionRide';

	late final Translations$nav$en nav = Translations$nav$en.internal(_root);
	late final Translations$home$en home = Translations$home$en.internal(_root);
	late final Translations$search$en search = Translations$search$en.internal(_root);
	late final Translations$vehicle$en vehicle = Translations$vehicle$en.internal(_root);
	late final Translations$tours$en tours = Translations$tours$en.internal(_root);
	late final Translations$booking$en booking = Translations$booking$en.internal(_root);
	late final Translations$provider$en provider = Translations$provider$en.internal(_root);
	late final Translations$profile$en profile = Translations$profile$en.internal(_root);
	late final Translations$telematics$en telematics = Translations$telematics$en.internal(_root);
	late final Translations$documents$en documents = Translations$documents$en.internal(_root);
	late final Translations$common$en common = Translations$common$en.internal(_root);
}

// Path: nav
class Translations$nav$en {
	Translations$nav$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Home'
	String get home => 'Home';

	/// en: 'Rides'
	String get rides => 'Rides';

	/// en: 'Wallet'
	String get wallet => 'Wallet';

	/// en: 'Provider'
	String get provider => 'Provider';

	/// en: 'Profile'
	String get profile => 'Profile';

	/// en: 'Search'
	String get search => 'Search';

	/// en: 'Bookings'
	String get bookings => 'Bookings';

	/// en: 'Chat'
	String get chat => 'Chat';

	/// en: 'Inbox'
	String get inbox => 'Inbox';

	/// en: 'Saved'
	String get saved => 'Saved';

	/// en: 'Host'
	String get host => 'Host';

	/// en: 'Earnings'
	String get earnings => 'Earnings';
}

// Path: home
class Translations$home$en {
	Translations$home$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'P2P KINETIC MARKETPLACE'
	String get heroTag => 'P2P KINETIC MARKETPLACE';

	/// en: 'Find your next ride or join a guided trip'
	String get heroTitle => 'Find your next ride or join a guided trip';

	/// en: 'Search city, vehicle model, or tour destination...'
	String get searchPlaceholder => 'Search city, vehicle model, or tour destination...';

	/// en: 'Explore Vehicles'
	String get exploreVehicles => 'Explore Vehicles';

	/// en: 'Guided Group Tours'
	String get guidedTours => 'Guided Group Tours';

	/// en: 'Featured Vehicle Rentals'
	String get featuredRides => 'Featured Vehicle Rentals';

	/// en: 'Popular Guided Expeditions'
	String get popularTours => 'Popular Guided Expeditions';

	/// en: 'Kinetic Trust & Verified Hosts'
	String get trustMarketplace => 'Kinetic Trust & Verified Hosts';

	/// en: 'View All'
	String get viewAll => 'View All';

	/// en: 'Near Your Location'
	String get nearYou => 'Near Your Location';

	/// en: '/ day'
	String get perDay => '/ day';

	/// en: '/ person'
	String get perPerson => '/ person';
}

// Path: search
class Translations$search$en {
	Translations$search$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Discover Vehicles & Tours'
	String get title => 'Discover Vehicles & Tours';

	/// en: 'Filter'
	String get filter => 'Filter';

	/// en: 'Location'
	String get location => 'Location';

	/// en: 'Price Range'
	String get priceRange => 'Price Range';

	/// en: 'Vehicle Type'
	String get vehicleType => 'Vehicle Type';

	/// en: 'All Types'
	String get allTypes => 'All Types';

	/// en: 'Cars'
	String get cars => 'Cars';

	/// en: 'Bicycles & Bikes'
	String get bikes => 'Bicycles & Bikes';

	/// en: 'Scooters & EVs'
	String get scooters => 'Scooters & EVs';

	/// en: 'Guided Tours'
	String get tours => 'Guided Tours';

	/// en: 'Results Found'
	String get resultsFound => 'Results Found';

	/// en: 'No listings match your filter'
	String get noResults => 'No listings match your filter';

	/// en: 'Reset Filters'
	String get resetFilters => 'Reset Filters';
}

// Path: vehicle
class Translations$vehicle$en {
	Translations$vehicle$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Vehicle Details'
	String get details => 'Vehicle Details';

	/// en: 'Specifications'
	String get specs => 'Specifications';

	/// en: 'Price per Day'
	String get pricePerDay => 'Price per Day';

	/// en: 'Reserve & Book Now'
	String get bookNow => 'Reserve & Book Now';

	/// en: 'IoT Keyless Unlock Included'
	String get keylessUnlock => 'IoT Keyless Unlock Included';

	/// en: 'Vehicle Features'
	String get features => 'Vehicle Features';

	/// en: 'Host Information'
	String get hostInfo => 'Host Information';

	/// en: 'Pickup & Dropoff Location'
	String get locationMap => 'Pickup & Dropoff Location';

	/// en: 'Rider Reviews & Ratings'
	String get reviews => 'Rider Reviews & Ratings';

	/// en: 'Rating'
	String get rating => 'Rating';

	/// en: 'Transmission'
	String get transmission => 'Transmission';

	/// en: 'Fuel / EV Type'
	String get fuelType => 'Fuel / EV Type';

	/// en: 'Seats'
	String get seats => 'Seats';
}

// Path: tours
class Translations$tours$en {
	Translations$tours$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Guided Group Tour'
	String get guidedTrip => 'Guided Group Tour';

	/// en: 'Tour Itinerary'
	String get itinerary => 'Tour Itinerary';

	/// en: 'Duration'
	String get duration => 'Duration';

	/// en: 'Max Group Size'
	String get groupSize => 'Max Group Size';

	/// en: 'Included Services'
	String get includedServices => 'Included Services';

	/// en: 'Join Expedition'
	String get joinTour => 'Join Expedition';

	/// en: 'Tour Leader / Guide'
	String get hostGuide => 'Tour Leader / Guide';

	/// en: 'Trip Highlights'
	String get highlights => 'Trip Highlights';

	/// en: 'Departure Date'
	String get departureDate => 'Departure Date';

	/// en: 'Meeting Point'
	String get meetingPoint => 'Meeting Point';
}

// Path: booking
class Translations$booking$en {
	Translations$booking$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Booking Verification & PIN'
	String get verification => 'Booking Verification & PIN';

	/// en: 'Payment Checkout'
	String get checkout => 'Payment Checkout';

	/// en: 'Complete Payment'
	String get payment => 'Complete Payment';

	/// en: 'Total Amount'
	String get totalAmount => 'Total Amount';

	/// en: 'Pay via Razorpay / UPI'
	String get payWithRazorpay => 'Pay via Razorpay / UPI';

	/// en: 'Verify Rental Unlock PIN'
	String get pinVerification => 'Verify Rental Unlock PIN';

	/// en: 'Confirm & Reserve'
	String get confirmBooking => 'Confirm & Reserve';

	/// en: 'Booking Confirmed Successfully!'
	String get success => 'Booking Confirmed Successfully!';

	/// en: 'Booking Status'
	String get status => 'Booking Status';

	/// en: 'Active'
	String get active => 'Active';

	/// en: 'Completed'
	String get completed => 'Completed';

	/// en: 'Cancelled'
	String get cancelled => 'Cancelled';
}

// Path: provider
class Translations$provider$en {
	Translations$provider$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Host Fleet Dashboard'
	String get fleetDashboard => 'Host Fleet Dashboard';

	/// en: 'Financial Earnings'
	String get earnings => 'Financial Earnings';

	/// en: 'Register New Vehicle'
	String get addVehicle => 'Register New Vehicle';

	/// en: 'Publish Guided Tour'
	String get addTour => 'Publish Guided Tour';

	/// en: 'Register Listing'
	String get registerListing => 'Register Listing';

	/// en: 'Active Fleet Listings'
	String get activeListings => 'Active Fleet Listings';

	/// en: 'Monthly Revenue'
	String get monthlyRevenue => 'Monthly Revenue';

	/// en: 'Manage Listings'
	String get manageFleet => 'Manage Listings';
}

// Path: profile
class Translations$profile$en {
	Translations$profile$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'My Profile'
	String get title => 'My Profile';

	/// en: 'Personal Information'
	String get personalInfo => 'Personal Information';

	/// en: 'Vehicle Details'
	String get vehicleInfo => 'Vehicle Details';

	/// en: 'Driver's License'
	String get driverLicense => 'Driver\'s License';

	/// en: 'App Language'
	String get language => 'App Language';

	/// en: 'Settings'
	String get settings => 'Settings';

	/// en: 'Log Out'
	String get logout => 'Log Out';

	/// en: 'Edit Profile'
	String get editProfile => 'Edit Profile';

	/// en: 'Verified'
	String get verified => 'Verified';

	/// en: 'Account & Preferences'
	String get accountPreferences => 'Account & Preferences';

	/// en: 'Dark Mode Theme'
	String get darkMode => 'Dark Mode Theme';

	/// en: 'Toggle dark or light app theme'
	String get darkModeSubtitle => 'Toggle dark or light app theme';

	/// en: 'Documents & Licenses'
	String get documents => 'Documents & Licenses';

	/// en: 'Driving license, Aadhar card & government ID'
	String get documentsSubtitle => 'Driving license, Aadhar card & government ID';

	/// en: 'Kinetic Trust Reputation'
	String get trustReputation => 'Kinetic Trust Reputation';

	/// en: 'View trust score breakdown & badges'
	String get trustReputationSubtitle => 'View trust score breakdown & badges';

	/// en: 'Password Reset'
	String get passwordReset => 'Password Reset';

	/// en: 'Send security password reset email'
	String get passwordResetSubtitle => 'Send security password reset email';

	/// en: 'Provider Financials'
	String get financials => 'Provider Financials';

	/// en: 'Earnings, payouts & banking info'
	String get financialsSubtitle => 'Earnings, payouts & banking info';

	/// en: 'AI Tour Generator'
	String get aiGenerator => 'AI Tour Generator';

	/// en: 'Create itinerary using AI Co-Pilot'
	String get aiGeneratorSubtitle => 'Create itinerary using AI Co-Pilot';

	/// en: 'In-App Web Portal'
	String get inAppPortal => 'In-App Web Portal';

	/// en: 'Embed and view any external website directly'
	String get inAppPortalSubtitle => 'Embed and view any external website directly';

	/// en: 'Send App Feedback'
	String get feedback => 'Send App Feedback';

	/// en: 'Submit app experience review or report bugs'
	String get feedbackSubtitle => 'Submit app experience review or report bugs';

	/// en: 'Feedback & Trust Insights'
	String get feedbackInsights => 'Feedback & Trust Insights';

	/// en: 'View host review analytics & AI sentiment'
	String get feedbackInsightsSubtitle => 'View host review analytics & AI sentiment';

	/// en: 'Switch Role'
	String get switchRole => 'Switch Role';
}

// Path: telematics
class Translations$telematics$en {
	Translations$telematics$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Vehicle Telematics Hub'
	String get ioTHub => 'Vehicle Telematics Hub';

	/// en: 'Remote Lock / Unlock'
	String get remoteLock => 'Remote Lock / Unlock';

	/// en: 'Engine Status'
	String get engineStatus => 'Engine Status';

	/// en: 'Battery Level'
	String get batteryLevel => 'Battery Level';

	/// en: 'Live GPS Tracking'
	String get gpsTracking => 'Live GPS Tracking';

	/// en: 'Speed Alert System'
	String get speedAlert => 'Speed Alert System';
}

// Path: documents
class Translations$documents$en {
	Translations$documents$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Identity Verification'
	String get identityVerification => 'Identity Verification';

	/// en: 'Driving License'
	String get driverLicense => 'Driving License';

	/// en: 'Government ID / Aadhar'
	String get governmentId => 'Government ID / Aadhar';

	/// en: 'Compliance Status'
	String get complianceStatus => 'Compliance Status';

	/// en: 'Upload Document'
	String get uploadDoc => 'Upload Document';
}

// Path: common
class Translations$common$en {
	Translations$common$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Welcome back!'
	String get welcome => 'Welcome back!';

	/// en: 'Search...'
	String get search => 'Search...';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'Confirm'
	String get confirm => 'Confirm';

	/// en: 'Loading...'
	String get loading => 'Loading...';

	/// en: 'Something went wrong'
	String get error => 'Something went wrong';

	/// en: 'Select Language'
	String get selectLanguage => 'Select Language';

	/// en: 'Native Language'
	String get nativeLanguage => 'Native Language';

	/// en: 'Translating content...'
	String get dynamicTranslation => 'Translating content...';

	/// en: 'Close'
	String get close => 'Close';

	/// en: 'Back'
	String get back => 'Back';

	/// en: 'Details'
	String get details => 'Details';

	/// en: 'Status'
	String get status => 'Status';

	/// en: 'View'
	String get view => 'View';

	/// en: 'Submit'
	String get submit => 'Submit';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appName' => 'PassionRide',
			'nav.home' => 'Home',
			'nav.rides' => 'Rides',
			'nav.wallet' => 'Wallet',
			'nav.provider' => 'Provider',
			'nav.profile' => 'Profile',
			'nav.search' => 'Search',
			'nav.bookings' => 'Bookings',
			'nav.chat' => 'Chat',
			'nav.inbox' => 'Inbox',
			'nav.saved' => 'Saved',
			'nav.host' => 'Host',
			'nav.earnings' => 'Earnings',
			'home.heroTag' => 'P2P KINETIC MARKETPLACE',
			'home.heroTitle' => 'Find your next ride or join a guided trip',
			'home.searchPlaceholder' => 'Search city, vehicle model, or tour destination...',
			'home.exploreVehicles' => 'Explore Vehicles',
			'home.guidedTours' => 'Guided Group Tours',
			'home.featuredRides' => 'Featured Vehicle Rentals',
			'home.popularTours' => 'Popular Guided Expeditions',
			'home.trustMarketplace' => 'Kinetic Trust & Verified Hosts',
			'home.viewAll' => 'View All',
			'home.nearYou' => 'Near Your Location',
			'home.perDay' => '/ day',
			'home.perPerson' => '/ person',
			'search.title' => 'Discover Vehicles & Tours',
			'search.filter' => 'Filter',
			'search.location' => 'Location',
			'search.priceRange' => 'Price Range',
			'search.vehicleType' => 'Vehicle Type',
			'search.allTypes' => 'All Types',
			'search.cars' => 'Cars',
			'search.bikes' => 'Bicycles & Bikes',
			'search.scooters' => 'Scooters & EVs',
			'search.tours' => 'Guided Tours',
			'search.resultsFound' => 'Results Found',
			'search.noResults' => 'No listings match your filter',
			'search.resetFilters' => 'Reset Filters',
			'vehicle.details' => 'Vehicle Details',
			'vehicle.specs' => 'Specifications',
			'vehicle.pricePerDay' => 'Price per Day',
			'vehicle.bookNow' => 'Reserve & Book Now',
			'vehicle.keylessUnlock' => 'IoT Keyless Unlock Included',
			'vehicle.features' => 'Vehicle Features',
			'vehicle.hostInfo' => 'Host Information',
			'vehicle.locationMap' => 'Pickup & Dropoff Location',
			'vehicle.reviews' => 'Rider Reviews & Ratings',
			'vehicle.rating' => 'Rating',
			'vehicle.transmission' => 'Transmission',
			'vehicle.fuelType' => 'Fuel / EV Type',
			'vehicle.seats' => 'Seats',
			'tours.guidedTrip' => 'Guided Group Tour',
			'tours.itinerary' => 'Tour Itinerary',
			'tours.duration' => 'Duration',
			'tours.groupSize' => 'Max Group Size',
			'tours.includedServices' => 'Included Services',
			'tours.joinTour' => 'Join Expedition',
			'tours.hostGuide' => 'Tour Leader / Guide',
			'tours.highlights' => 'Trip Highlights',
			'tours.departureDate' => 'Departure Date',
			'tours.meetingPoint' => 'Meeting Point',
			'booking.verification' => 'Booking Verification & PIN',
			'booking.checkout' => 'Payment Checkout',
			'booking.payment' => 'Complete Payment',
			'booking.totalAmount' => 'Total Amount',
			'booking.payWithRazorpay' => 'Pay via Razorpay / UPI',
			'booking.pinVerification' => 'Verify Rental Unlock PIN',
			'booking.confirmBooking' => 'Confirm & Reserve',
			'booking.success' => 'Booking Confirmed Successfully!',
			'booking.status' => 'Booking Status',
			'booking.active' => 'Active',
			'booking.completed' => 'Completed',
			'booking.cancelled' => 'Cancelled',
			'provider.fleetDashboard' => 'Host Fleet Dashboard',
			'provider.earnings' => 'Financial Earnings',
			'provider.addVehicle' => 'Register New Vehicle',
			'provider.addTour' => 'Publish Guided Tour',
			'provider.registerListing' => 'Register Listing',
			'provider.activeListings' => 'Active Fleet Listings',
			'provider.monthlyRevenue' => 'Monthly Revenue',
			'provider.manageFleet' => 'Manage Listings',
			'profile.title' => 'My Profile',
			'profile.personalInfo' => 'Personal Information',
			'profile.vehicleInfo' => 'Vehicle Details',
			'profile.driverLicense' => 'Driver\'s License',
			'profile.language' => 'App Language',
			'profile.settings' => 'Settings',
			'profile.logout' => 'Log Out',
			'profile.editProfile' => 'Edit Profile',
			'profile.verified' => 'Verified',
			'profile.accountPreferences' => 'Account & Preferences',
			'profile.darkMode' => 'Dark Mode Theme',
			'profile.darkModeSubtitle' => 'Toggle dark or light app theme',
			'profile.documents' => 'Documents & Licenses',
			'profile.documentsSubtitle' => 'Driving license, Aadhar card & government ID',
			'profile.trustReputation' => 'Kinetic Trust Reputation',
			'profile.trustReputationSubtitle' => 'View trust score breakdown & badges',
			'profile.passwordReset' => 'Password Reset',
			'profile.passwordResetSubtitle' => 'Send security password reset email',
			'profile.financials' => 'Provider Financials',
			'profile.financialsSubtitle' => 'Earnings, payouts & banking info',
			'profile.aiGenerator' => 'AI Tour Generator',
			'profile.aiGeneratorSubtitle' => 'Create itinerary using AI Co-Pilot',
			'profile.inAppPortal' => 'In-App Web Portal',
			'profile.inAppPortalSubtitle' => 'Embed and view any external website directly',
			'profile.feedback' => 'Send App Feedback',
			'profile.feedbackSubtitle' => 'Submit app experience review or report bugs',
			'profile.feedbackInsights' => 'Feedback & Trust Insights',
			'profile.feedbackInsightsSubtitle' => 'View host review analytics & AI sentiment',
			'profile.switchRole' => 'Switch Role',
			'telematics.ioTHub' => 'Vehicle Telematics Hub',
			'telematics.remoteLock' => 'Remote Lock / Unlock',
			'telematics.engineStatus' => 'Engine Status',
			'telematics.batteryLevel' => 'Battery Level',
			'telematics.gpsTracking' => 'Live GPS Tracking',
			'telematics.speedAlert' => 'Speed Alert System',
			'documents.identityVerification' => 'Identity Verification',
			'documents.driverLicense' => 'Driving License',
			'documents.governmentId' => 'Government ID / Aadhar',
			'documents.complianceStatus' => 'Compliance Status',
			'documents.uploadDoc' => 'Upload Document',
			'common.welcome' => 'Welcome back!',
			'common.search' => 'Search...',
			'common.cancel' => 'Cancel',
			'common.save' => 'Save',
			'common.confirm' => 'Confirm',
			'common.loading' => 'Loading...',
			'common.error' => 'Something went wrong',
			'common.selectLanguage' => 'Select Language',
			'common.nativeLanguage' => 'Native Language',
			'common.dynamicTranslation' => 'Translating content...',
			'common.close' => 'Close',
			'common.back' => 'Back',
			'common.details' => 'Details',
			'common.status' => 'Status',
			'common.view' => 'View',
			'common.submit' => 'Submit',
			_ => null,
		};
	}
}
