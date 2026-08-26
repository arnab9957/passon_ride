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
class TranslationsHi extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsHi({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.hi,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <hi>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsHi _root = this; // ignore: unused_field

	@override 
	TranslationsHi $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsHi(meta: meta ?? this.$meta);

	// Translations
	@override String get appName => 'PassionRide';
	@override late final _Translations$nav$hi nav = _Translations$nav$hi._(_root);
	@override late final _Translations$home$hi home = _Translations$home$hi._(_root);
	@override late final _Translations$search$hi search = _Translations$search$hi._(_root);
	@override late final _Translations$vehicle$hi vehicle = _Translations$vehicle$hi._(_root);
	@override late final _Translations$tours$hi tours = _Translations$tours$hi._(_root);
	@override late final _Translations$booking$hi booking = _Translations$booking$hi._(_root);
	@override late final _Translations$provider$hi provider = _Translations$provider$hi._(_root);
	@override late final _Translations$profile$hi profile = _Translations$profile$hi._(_root);
	@override late final _Translations$telematics$hi telematics = _Translations$telematics$hi._(_root);
	@override late final _Translations$documents$hi documents = _Translations$documents$hi._(_root);
	@override late final _Translations$common$hi common = _Translations$common$hi._(_root);
}

// Path: nav
class _Translations$nav$hi extends Translations$nav$en {
	_Translations$nav$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get home => 'होम';
	@override String get rides => 'सवारी';
	@override String get wallet => 'वॉलेट';
	@override String get provider => 'प्रदाता';
	@override String get profile => 'प्रोफ़ाइल';
	@override String get search => 'खोजें';
	@override String get bookings => 'बुकिंग';
	@override String get chat => 'चैट';
	@override String get inbox => 'इनबॉक्स';
	@override String get saved => 'सहेजे गए';
	@override String get host => 'होस्ट';
	@override String get earnings => 'कमाई';
}

// Path: home
class _Translations$home$hi extends Translations$home$en {
	_Translations$home$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get heroTag => 'P2P काइनेटिक मार्केटप्लेस';
	@override String get heroTitle => 'अपनी अगली सवारी खोजें या किसी टूर में शामिल हों';
	@override String get searchPlaceholder => 'शहर, वाहन मॉडल, या गंतव्य खोजें...';
	@override String get exploreVehicles => 'वाहन खोजें';
	@override String get guidedTours => 'गाइडेड ग्रुप टूर';
	@override String get featuredRides => 'प्रमुख वाहन किराए पर';
	@override String get popularTours => 'लोकप्रिय गाइडेड यात्राएं';
	@override String get trustMarketplace => 'काइनेटिक ट्रस्ट और सत्यापित होस्ट';
	@override String get viewAll => 'सभी देखें';
	@override String get nearYou => 'आपके पास';
	@override String get perDay => '/ दिन';
	@override String get perPerson => '/ व्यक्ति';
}

// Path: search
class _Translations$search$hi extends Translations$search$en {
	_Translations$search$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'वाहन और टूर खोजें';
	@override String get filter => 'फ़िल्टर';
	@override String get location => 'स्थान';
	@override String get priceRange => 'मूल्य सीमा';
	@override String get vehicleType => 'वाहन का प्रकार';
	@override String get allTypes => 'सभी प्रकार';
	@override String get cars => 'कारें';
	@override String get bikes => 'साइकिल और बाइक';
	@override String get scooters => 'स्कूटर और ईवी';
	@override String get tours => 'गाइडेड टूर';
	@override String get resultsFound => 'परिणाम मिले';
	@override String get noResults => 'आपकी खोज का कोई परिणाम नहीं मिला';
	@override String get resetFilters => 'फ़िल्टर रीसेट करें';
}

// Path: vehicle
class _Translations$vehicle$hi extends Translations$vehicle$en {
	_Translations$vehicle$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get details => 'वाहन का विवरण';
	@override String get specs => 'विशेषताएं';
	@override String get pricePerDay => 'प्रति दिन मूल्य';
	@override String get bookNow => 'अभी बुक करें';
	@override String get keylessUnlock => 'IoT की-लेस अनलॉक शामिल';
	@override String get features => 'वाहन की विशेषताएं';
	@override String get hostInfo => 'होस्ट की जानकारी';
	@override String get locationMap => 'पिकअप और ड्रॉपऑफ़ स्थान';
	@override String get reviews => 'समीक्षाएं और रेटिंग';
	@override String get rating => 'रेटिंग';
	@override String get transmission => 'ट्रांसमिशन';
	@override String get fuelType => 'ईंधन / ईवी प्रकार';
	@override String get seats => 'सीटें';
}

// Path: tours
class _Translations$tours$hi extends Translations$tours$en {
	_Translations$tours$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get guidedTrip => 'गाइडेड ग्रुप टूर';
	@override String get itinerary => 'टूर यात्रा कार्यक्रम';
	@override String get duration => 'अवधि';
	@override String get groupSize => 'अधिकतम समूह आकार';
	@override String get includedServices => 'शामिल सेवाएं';
	@override String get joinTour => 'यात्रा में शामिल हों';
	@override String get hostGuide => 'टूर गाइड / लीडर';
	@override String get highlights => 'मुख्य विशेषताएं';
	@override String get departureDate => 'प्रस्थान की तिथि';
	@override String get meetingPoint => 'मिलने का स्थान';
}

// Path: booking
class _Translations$booking$hi extends Translations$booking$en {
	_Translations$booking$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get verification => 'बुकिंग सत्यापन और पिन';
	@override String get checkout => 'भुगतान चेकआउट';
	@override String get payment => 'भुगतान पूरा करें';
	@override String get totalAmount => 'कुल राशि';
	@override String get payWithRazorpay => 'Razorpay / UPI द्वारा भुगतान करें';
	@override String get pinVerification => 'अनलॉक पिन सत्यापित करें';
	@override String get confirmBooking => 'पुष्टि करें और बुक करें';
	@override String get success => 'बुकिंग सफलतापूर्वक सफल हुई!';
	@override String get status => 'बुकिंग स्थिति';
	@override String get active => 'सक्रिय';
	@override String get completed => 'पूर्ण';
	@override String get cancelled => 'रद्द';
}

// Path: provider
class _Translations$provider$hi extends Translations$provider$en {
	_Translations$provider$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get fleetDashboard => 'होस्ट बेड़ा डैशबोर्ड';
	@override String get earnings => 'वित्तीय कमाई';
	@override String get addVehicle => 'नया वाहन पंजीकृत करें';
	@override String get addTour => 'गाइडेड टूर प्रकाशित करें';
	@override String get registerListing => 'लिस्टिंग पंजीकृत करें';
	@override String get activeListings => 'सक्रिय वाहन लिस्टिंग';
	@override String get monthlyRevenue => 'मासिक आय';
	@override String get manageFleet => 'लिस्टिंग प्रबंधित करें';
}

// Path: profile
class _Translations$profile$hi extends Translations$profile$en {
	_Translations$profile$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get title => 'मेरी प्रोफ़ाइल';
	@override String get personalInfo => 'व्यक्तिगत जानकारी';
	@override String get vehicleInfo => 'वाहन विवरण';
	@override String get driverLicense => 'ड्राइविंग लाइसेंस';
	@override String get language => 'ऐप की भाषा';
	@override String get settings => 'सेटिंग्स';
	@override String get logout => 'लॉग आउट';
	@override String get editProfile => 'प्रोफ़ाइल संपादित करें';
	@override String get verified => 'सत्यापित';
	@override String get accountPreferences => 'खाता और प्राथमिकताएं';
	@override String get darkMode => 'डार्क मोड थीम';
	@override String get darkModeSubtitle => 'डार्क या लाइट ऐप थीम बदलें';
	@override String get documents => 'दस्तावेज़ और लाइसेंस';
	@override String get documentsSubtitle => 'ड्राइविंग लाइसेंस, आधार कार्ड और आईडी';
	@override String get trustReputation => 'काइनेटिक ट्रस्ट प्रतिष्ठा';
	@override String get trustReputationSubtitle => 'विश्वास स्कोर ब्रेकडाउन और बैज देखें';
	@override String get passwordReset => 'पासवर्ड रीसेट';
	@override String get passwordResetSubtitle => 'सुरक्षा पासवर्ड रीसेट ईमेल भेजें';
	@override String get financials => 'प्रदाता वित्तीय';
	@override String get financialsSubtitle => 'कमाई, भुगतान और बैंकिंग जानकारी';
	@override String get aiGenerator => 'एआई टूर जनरेटर';
	@override String get aiGeneratorSubtitle => 'एआई सह-पायलट का उपयोग करके यात्रा कार्यक्रम बनाएं';
	@override String get inAppPortal => 'इन-ऐप वेब पोर्टल';
	@override String get inAppPortalSubtitle => 'सीधे किसी भी बाहरी वेबसाइट को देखें';
	@override String get feedback => 'ऐप प्रतिक्रिया भेजें';
	@override String get feedbackSubtitle => 'ऐप अनुभव समीक्षा या बग रिपोर्ट जमा करें';
	@override String get feedbackInsights => 'प्रतिक्रिया और ट्रस्ट इनसाइट्स';
	@override String get feedbackInsightsSubtitle => 'होस्ट समीक्षा विश्लेषिकी और एआई भावना देखें';
	@override String get switchRole => 'भूमिका बदलें';
}

// Path: telematics
class _Translations$telematics$hi extends Translations$telematics$en {
	_Translations$telematics$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get ioTHub => 'वाहन टेलीमैटिक्स हब';
	@override String get remoteLock => 'रिमोट लॉक / अनलॉक';
	@override String get engineStatus => 'इंजन की स्थिति';
	@override String get batteryLevel => 'बैटरी का स्तर';
	@override String get gpsTracking => 'लाइव जीपीएस ट्रैकिंग';
	@override String get speedAlert => 'गति चेतावनी प्रणाली';
}

// Path: documents
class _Translations$documents$hi extends Translations$documents$en {
	_Translations$documents$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get identityVerification => 'पहचान सत्यापन';
	@override String get driverLicense => 'ड्राइविंग लाइसेंस';
	@override String get governmentId => 'सरकारी पहचान पत्र';
	@override String get complianceStatus => 'अनुपालन स्थिति';
	@override String get uploadDoc => 'दस्तावेज़ अपलोड करें';
}

// Path: common
class _Translations$common$hi extends Translations$common$en {
	_Translations$common$hi._(TranslationsHi root) : this._root = root, super.internal(root);

	final TranslationsHi _root; // ignore: unused_field

	// Translations
	@override String get welcome => 'वापसी पर आपका स्वागत है!';
	@override String get search => 'खोजें...';
	@override String get cancel => 'रद्द करें';
	@override String get save => 'सहेजें';
	@override String get confirm => 'पुष्टि करें';
	@override String get loading => 'लोड हो रहा है...';
	@override String get error => 'कुछ गलत हो गया';
	@override String get selectLanguage => 'भाषा चुनें';
	@override String get nativeLanguage => 'मूल भाषा';
	@override String get dynamicTranslation => 'सामग्री का अनुवाद किया जा रहा है...';
	@override String get close => 'बंद करें';
	@override String get back => 'वापस';
	@override String get details => 'विवरण';
	@override String get status => 'स्थिति';
	@override String get view => 'देखें';
	@override String get submit => 'जमा करें';
}

/// The flat map containing all translations for locale <hi>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsHi {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appName' => 'PassionRide',
			'nav.home' => 'होम',
			'nav.rides' => 'सवारी',
			'nav.wallet' => 'वॉलेट',
			'nav.provider' => 'प्रदाता',
			'nav.profile' => 'प्रोफ़ाइल',
			'nav.search' => 'खोजें',
			'nav.bookings' => 'बुकिंग',
			'nav.chat' => 'चैट',
			'nav.inbox' => 'इनबॉक्स',
			'nav.saved' => 'सहेजे गए',
			'nav.host' => 'होस्ट',
			'nav.earnings' => 'कमाई',
			'home.heroTag' => 'P2P काइनेटिक मार्केटप्लेस',
			'home.heroTitle' => 'अपनी अगली सवारी खोजें या किसी टूर में शामिल हों',
			'home.searchPlaceholder' => 'शहर, वाहन मॉडल, या गंतव्य खोजें...',
			'home.exploreVehicles' => 'वाहन खोजें',
			'home.guidedTours' => 'गाइडेड ग्रुप टूर',
			'home.featuredRides' => 'प्रमुख वाहन किराए पर',
			'home.popularTours' => 'लोकप्रिय गाइडेड यात्राएं',
			'home.trustMarketplace' => 'काइनेटिक ट्रस्ट और सत्यापित होस्ट',
			'home.viewAll' => 'सभी देखें',
			'home.nearYou' => 'आपके पास',
			'home.perDay' => '/ दिन',
			'home.perPerson' => '/ व्यक्ति',
			'search.title' => 'वाहन और टूर खोजें',
			'search.filter' => 'फ़िल्टर',
			'search.location' => 'स्थान',
			'search.priceRange' => 'मूल्य सीमा',
			'search.vehicleType' => 'वाहन का प्रकार',
			'search.allTypes' => 'सभी प्रकार',
			'search.cars' => 'कारें',
			'search.bikes' => 'साइकिल और बाइक',
			'search.scooters' => 'स्कूटर और ईवी',
			'search.tours' => 'गाइडेड टूर',
			'search.resultsFound' => 'परिणाम मिले',
			'search.noResults' => 'आपकी खोज का कोई परिणाम नहीं मिला',
			'search.resetFilters' => 'फ़िल्टर रीसेट करें',
			'vehicle.details' => 'वाहन का विवरण',
			'vehicle.specs' => 'विशेषताएं',
			'vehicle.pricePerDay' => 'प्रति दिन मूल्य',
			'vehicle.bookNow' => 'अभी बुक करें',
			'vehicle.keylessUnlock' => 'IoT की-लेस अनलॉक शामिल',
			'vehicle.features' => 'वाहन की विशेषताएं',
			'vehicle.hostInfo' => 'होस्ट की जानकारी',
			'vehicle.locationMap' => 'पिकअप और ड्रॉपऑफ़ स्थान',
			'vehicle.reviews' => 'समीक्षाएं और रेटिंग',
			'vehicle.rating' => 'रेटिंग',
			'vehicle.transmission' => 'ट्रांसमिशन',
			'vehicle.fuelType' => 'ईंधन / ईवी प्रकार',
			'vehicle.seats' => 'सीटें',
			'tours.guidedTrip' => 'गाइडेड ग्रुप टूर',
			'tours.itinerary' => 'टूर यात्रा कार्यक्रम',
			'tours.duration' => 'अवधि',
			'tours.groupSize' => 'अधिकतम समूह आकार',
			'tours.includedServices' => 'शामिल सेवाएं',
			'tours.joinTour' => 'यात्रा में शामिल हों',
			'tours.hostGuide' => 'टूर गाइड / लीडर',
			'tours.highlights' => 'मुख्य विशेषताएं',
			'tours.departureDate' => 'प्रस्थान की तिथि',
			'tours.meetingPoint' => 'मिलने का स्थान',
			'booking.verification' => 'बुकिंग सत्यापन और पिन',
			'booking.checkout' => 'भुगतान चेकआउट',
			'booking.payment' => 'भुगतान पूरा करें',
			'booking.totalAmount' => 'कुल राशि',
			'booking.payWithRazorpay' => 'Razorpay / UPI द्वारा भुगतान करें',
			'booking.pinVerification' => 'अनलॉक पिन सत्यापित करें',
			'booking.confirmBooking' => 'पुष्टि करें और बुक करें',
			'booking.success' => 'बुकिंग सफलतापूर्वक सफल हुई!',
			'booking.status' => 'बुकिंग स्थिति',
			'booking.active' => 'सक्रिय',
			'booking.completed' => 'पूर्ण',
			'booking.cancelled' => 'रद्द',
			'provider.fleetDashboard' => 'होस्ट बेड़ा डैशबोर्ड',
			'provider.earnings' => 'वित्तीय कमाई',
			'provider.addVehicle' => 'नया वाहन पंजीकृत करें',
			'provider.addTour' => 'गाइडेड टूर प्रकाशित करें',
			'provider.registerListing' => 'लिस्टिंग पंजीकृत करें',
			'provider.activeListings' => 'सक्रिय वाहन लिस्टिंग',
			'provider.monthlyRevenue' => 'मासिक आय',
			'provider.manageFleet' => 'लिस्टिंग प्रबंधित करें',
			'profile.title' => 'मेरी प्रोफ़ाइल',
			'profile.personalInfo' => 'व्यक्तिगत जानकारी',
			'profile.vehicleInfo' => 'वाहन विवरण',
			'profile.driverLicense' => 'ड्राइविंग लाइसेंस',
			'profile.language' => 'ऐप की भाषा',
			'profile.settings' => 'सेटिंग्स',
			'profile.logout' => 'लॉग आउट',
			'profile.editProfile' => 'प्रोफ़ाइल संपादित करें',
			'profile.verified' => 'सत्यापित',
			'profile.accountPreferences' => 'खाता और प्राथमिकताएं',
			'profile.darkMode' => 'डार्क मोड थीम',
			'profile.darkModeSubtitle' => 'डार्क या लाइट ऐप थीम बदलें',
			'profile.documents' => 'दस्तावेज़ और लाइसेंस',
			'profile.documentsSubtitle' => 'ड्राइविंग लाइसेंस, आधार कार्ड और आईडी',
			'profile.trustReputation' => 'काइनेटिक ट्रस्ट प्रतिष्ठा',
			'profile.trustReputationSubtitle' => 'विश्वास स्कोर ब्रेकडाउन और बैज देखें',
			'profile.passwordReset' => 'पासवर्ड रीसेट',
			'profile.passwordResetSubtitle' => 'सुरक्षा पासवर्ड रीसेट ईमेल भेजें',
			'profile.financials' => 'प्रदाता वित्तीय',
			'profile.financialsSubtitle' => 'कमाई, भुगतान और बैंकिंग जानकारी',
			'profile.aiGenerator' => 'एआई टूर जनरेटर',
			'profile.aiGeneratorSubtitle' => 'एआई सह-पायलट का उपयोग करके यात्रा कार्यक्रम बनाएं',
			'profile.inAppPortal' => 'इन-ऐप वेब पोर्टल',
			'profile.inAppPortalSubtitle' => 'सीधे किसी भी बाहरी वेबसाइट को देखें',
			'profile.feedback' => 'ऐप प्रतिक्रिया भेजें',
			'profile.feedbackSubtitle' => 'ऐप अनुभव समीक्षा या बग रिपोर्ट जमा करें',
			'profile.feedbackInsights' => 'प्रतिक्रिया और ट्रस्ट इनसाइट्स',
			'profile.feedbackInsightsSubtitle' => 'होस्ट समीक्षा विश्लेषिकी और एआई भावना देखें',
			'profile.switchRole' => 'भूमिका बदलें',
			'telematics.ioTHub' => 'वाहन टेलीमैटिक्स हब',
			'telematics.remoteLock' => 'रिमोट लॉक / अनलॉक',
			'telematics.engineStatus' => 'इंजन की स्थिति',
			'telematics.batteryLevel' => 'बैटरी का स्तर',
			'telematics.gpsTracking' => 'लाइव जीपीएस ट्रैकिंग',
			'telematics.speedAlert' => 'गति चेतावनी प्रणाली',
			'documents.identityVerification' => 'पहचान सत्यापन',
			'documents.driverLicense' => 'ड्राइविंग लाइसेंस',
			'documents.governmentId' => 'सरकारी पहचान पत्र',
			'documents.complianceStatus' => 'अनुपालन स्थिति',
			'documents.uploadDoc' => 'दस्तावेज़ अपलोड करें',
			'common.welcome' => 'वापसी पर आपका स्वागत है!',
			'common.search' => 'खोजें...',
			'common.cancel' => 'रद्द करें',
			'common.save' => 'सहेजें',
			'common.confirm' => 'पुष्टि करें',
			'common.loading' => 'लोड हो रहा है...',
			'common.error' => 'कुछ गलत हो गया',
			'common.selectLanguage' => 'भाषा चुनें',
			'common.nativeLanguage' => 'मूल भाषा',
			'common.dynamicTranslation' => 'सामग्री का अनुवाद किया जा रहा है...',
			'common.close' => 'बंद करें',
			'common.back' => 'वापस',
			'common.details' => 'विवरण',
			'common.status' => 'स्थिति',
			'common.view' => 'देखें',
			'common.submit' => 'जमा करें',
			_ => null,
		};
	}
}
