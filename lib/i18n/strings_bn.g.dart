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
class TranslationsBn extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsBn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.bn,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <bn>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsBn _root = this; // ignore: unused_field

	@override 
	TranslationsBn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsBn(meta: meta ?? this.$meta);

	// Translations
	@override String get appName => 'PassionRide';
	@override late final _Translations$nav$bn nav = _Translations$nav$bn._(_root);
	@override late final _Translations$home$bn home = _Translations$home$bn._(_root);
	@override late final _Translations$search$bn search = _Translations$search$bn._(_root);
	@override late final _Translations$vehicle$bn vehicle = _Translations$vehicle$bn._(_root);
	@override late final _Translations$tours$bn tours = _Translations$tours$bn._(_root);
	@override late final _Translations$booking$bn booking = _Translations$booking$bn._(_root);
	@override late final _Translations$provider$bn provider = _Translations$provider$bn._(_root);
	@override late final _Translations$profile$bn profile = _Translations$profile$bn._(_root);
	@override late final _Translations$telematics$bn telematics = _Translations$telematics$bn._(_root);
	@override late final _Translations$documents$bn documents = _Translations$documents$bn._(_root);
	@override late final _Translations$common$bn common = _Translations$common$bn._(_root);
}

// Path: nav
class _Translations$nav$bn extends Translations$nav$en {
	_Translations$nav$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get home => 'হোম';
	@override String get rides => 'রাইড';
	@override String get wallet => 'ওয়ালেট';
	@override String get provider => 'প্রোভাইডার';
	@override String get profile => 'প্রোফাইল';
	@override String get search => 'সন্ধান';
	@override String get bookings => 'বুকিং';
	@override String get chat => 'চ্যাট';
	@override String get inbox => 'ইনবক্স';
	@override String get saved => 'সংরক্ষিত';
	@override String get host => 'হোস্ট';
	@override String get earnings => 'আয়';
}

// Path: home
class _Translations$home$bn extends Translations$home$en {
	_Translations$home$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get heroTag => 'P2P কাইনেটিক মার্কেটপ্লেস';
	@override String get heroTitle => 'আপনার পরবর্তী রাইড খুঁজুন বা গাইডেড ট্যুরে যোগ দিন';
	@override String get searchPlaceholder => 'শহর, গাড়ির মডেল বা গন্তব্য অনুসন্ধান করুন...';
	@override String get exploreVehicles => 'যানবাহন দেখুন';
	@override String get guidedTours => 'গাইডেড গ্রুপ ট্যুর';
	@override String get featuredRides => 'বিশেষ যানবাহন রেন্টাল';
	@override String get popularTours => 'জনপ্রিয় গাইডেড অভিযান';
	@override String get trustMarketplace => 'কাইনেটিক ট্রাস্ট ও যাচাইকৃত হোস্ট';
	@override String get viewAll => 'সব দেখুন';
	@override String get nearYou => 'আপনার কাছাকাছি';
	@override String get perDay => '/ দিন';
	@override String get perPerson => '/ জন';
}

// Path: search
class _Translations$search$bn extends Translations$search$en {
	_Translations$search$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'যানবাহন ও ট্যুর অনুসন্ধান করুন';
	@override String get filter => 'ফিল্টার';
	@override String get location => 'অবস্থান';
	@override String get priceRange => 'মূল্যের পরিসীমা';
	@override String get vehicleType => 'যানবাহনের ধরন';
	@override String get allTypes => 'সব ধরন';
	@override String get cars => 'গাড়ি';
	@override String get bikes => 'বাইসাইকেল ও বাইক';
	@override String get scooters => 'স্কুটার ও ইভি';
	@override String get tours => 'গাইডেড ট্যুর';
	@override String get resultsFound => 'ফলাফল পাওয়া গেছে';
	@override String get noResults => 'কোন ফলাফল পাওয়া যায়নি';
	@override String get resetFilters => 'ফিল্টার রিসেট করুন';
}

// Path: vehicle
class _Translations$vehicle$bn extends Translations$vehicle$en {
	_Translations$vehicle$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get details => 'যানবাহনের বিবরণ';
	@override String get specs => 'স্পেসিফিকেশন';
	@override String get pricePerDay => 'দৈনিক মূল্য';
	@override String get bookNow => 'এখনই বুক করুন';
	@override String get keylessUnlock => 'IoT কি-লেস আনলক অন্তর্ভুক্ত';
	@override String get features => 'যানবাহনের বৈশিষ্ট্য';
	@override String get hostInfo => 'হোস্ট তথ্য';
	@override String get locationMap => 'পিকআপ এবং ড্রপঅফ স্থান';
	@override String get reviews => 'রিভিউ এবং রেটিং';
	@override String get rating => 'রেটিং';
	@override String get transmission => 'ট্রান্সমিশন';
	@override String get fuelType => 'জ্বালানি / ইভি ধরন';
	@override String get seats => 'সিট';
}

// Path: tours
class _Translations$tours$bn extends Translations$tours$en {
	_Translations$tours$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get guidedTrip => 'গাইডেড গ্রুপ ট্যুর';
	@override String get itinerary => 'ট্যুর ভ্রমণসূচী';
	@override String get duration => 'সময়কাল';
	@override String get groupSize => 'সর্বোচ্চ গ্রুপ আকার';
	@override String get includedServices => 'অন্তর্ভুক্ত পরিষেবা';
	@override String get joinTour => 'অভিযানে যোগ দিন';
	@override String get hostGuide => 'ট্যুর গাইড / লিডার';
	@override String get highlights => 'প্রধান আকর্ষণ';
	@override String get departureDate => 'যাত্রার তারিখ';
	@override String get meetingPoint => 'সাক্ষাতের স্থান';
}

// Path: booking
class _Translations$booking$bn extends Translations$booking$en {
	_Translations$booking$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get verification => 'বুকিং যাচাইকরণ এবং পিন';
	@override String get checkout => 'পেমেন্ট চেকআউট';
	@override String get payment => 'পেমেন্ট সম্পন্ন করুন';
	@override String get totalAmount => 'মোট পরিমাণ';
	@override String get payWithRazorpay => 'Razorpay / UPI এর মাধ্যমে দিন';
	@override String get pinVerification => 'আনলক পিন যাচাই করুন';
	@override String get confirmBooking => 'নিশ্চিত করুন ও বুক করুন';
	@override String get success => 'বুকিং সফলভাবে নিশ্চিত হয়েছে!';
	@override String get status => 'বুকিং এর অবস্থা';
	@override String get active => 'সক্রিয়';
	@override String get completed => 'সম্পন্ন';
	@override String get cancelled => 'বাতিল';
}

// Path: provider
class _Translations$provider$bn extends Translations$provider$en {
	_Translations$provider$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get fleetDashboard => 'হোস্ট ফ্লিট ড্যাশবোর্ড';
	@override String get earnings => 'আর্থিক উপার্জন';
	@override String get addVehicle => 'নতুন গাড়ি নিবন্ধন করুন';
	@override String get addTour => 'গাইডেড ট্যুর প্রকাশ করুন';
	@override String get registerListing => 'লিস্টিং নিবন্ধন করুন';
	@override String get activeListings => 'সক্রিয় যানবাহন লিস্টিং';
	@override String get monthlyRevenue => 'মাসিক আয়';
	@override String get manageFleet => 'লিস্টিং পরিচালনা করুন';
}

// Path: profile
class _Translations$profile$bn extends Translations$profile$en {
	_Translations$profile$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get title => 'আমার প্রোফাইল';
	@override String get personalInfo => 'ব্যক্তিগত তথ্য';
	@override String get vehicleInfo => 'যানবাহনের বিবরণ';
	@override String get driverLicense => 'ড্রাইভিং লাইসেন্স';
	@override String get language => 'অ্যাপের ভাষা';
	@override String get settings => 'সেটিংস';
	@override String get logout => 'লগ আউট';
	@override String get editProfile => 'প্রোফাইল সম্পাদনা করুন';
	@override String get verified => 'যাচাইকৃত';
	@override String get accountPreferences => 'অ্যাকাউন্ট ও পছন্দসমূহ';
	@override String get darkMode => 'ডার্ক মোড থিম';
	@override String get darkModeSubtitle => 'ডার্ক বা লাইট অ্যাপ থিম পরিবর্তন করুন';
	@override String get documents => 'নথিপত্র ও লাইসেন্স';
	@override String get documentsSubtitle => 'ড্রাইভিং লাইসেন্স, আধার কার্ড এবং সরকারি আইডি';
	@override String get trustReputation => 'কাইনেটিক ট্রাস্ট সুনাম';
	@override String get trustReputationSubtitle => 'ট্রাস্ট স্কোর ব্রেকডাউন এবং ব্যাজ দেখুন';
	@override String get passwordReset => 'পাসওয়ার্ড রিসেট';
	@override String get passwordResetSubtitle => 'নিরাপত্তা পাসওয়ার্ড রিসেট ইমেল পাঠান';
	@override String get financials => 'প্রোভাইডার আর্থিক হিসাব';
	@override String get financialsSubtitle => 'উপার্জন, পেআউট এবং ব্যাংকিং তথ্য';
	@override String get aiGenerator => 'এআই ট্যুর জেনারেটর';
	@override String get aiGeneratorSubtitle => 'এআই কো-পাইলটের সাহায্যে সফরসূচি তৈরি করুন';
	@override String get inAppPortal => 'ইন-অ্যাপ ওয়েব পোর্টাল';
	@override String get inAppPortalSubtitle => 'যেকোনো বাহ্যিক ওয়েবসাইট সরাসরি দেখুন';
	@override String get feedback => 'মতামত জানান';
	@override String get feedbackSubtitle => 'অ্যাপ অভিজ্ঞতা পর্যালোচনা বা বাগ জমা দিন';
	@override String get feedbackInsights => 'ফিডব্যাক এবং ট্রাস্ট ইনসাইট';
	@override String get feedbackInsightsSubtitle => 'হোস্টের পর্যালোচনার বিশ্লেষণ দেখুন';
	@override String get switchRole => 'ভূমিকা পরিবর্তন করুন';
}

// Path: telematics
class _Translations$telematics$bn extends Translations$telematics$en {
	_Translations$telematics$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get ioTHub => 'যানবাহন টেলিমেটিক্স হাব';
	@override String get remoteLock => 'রিমোট লক / আনলক';
	@override String get engineStatus => 'ইঞ্জিনের অবস্থা';
	@override String get batteryLevel => 'ব্যাটারির মাত্রা';
	@override String get gpsTracking => 'লাইভ জিপিএস ট্র্যাকিং';
	@override String get speedAlert => 'গতি সতর্কতা সিস্টেম';
}

// Path: documents
class _Translations$documents$bn extends Translations$documents$en {
	_Translations$documents$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get identityVerification => 'পরিচয় যাচাইকরণ';
	@override String get driverLicense => 'ড্রাইভিং লাইসেন্স';
	@override String get governmentId => 'সরকারি পরিচয়পত্র';
	@override String get complianceStatus => 'সম্মতি অবস্থা';
	@override String get uploadDoc => 'নথি আপলোড করুন';
}

// Path: common
class _Translations$common$bn extends Translations$common$en {
	_Translations$common$bn._(TranslationsBn root) : this._root = root, super.internal(root);

	final TranslationsBn _root; // ignore: unused_field

	// Translations
	@override String get welcome => 'স্বাগতম!';
	@override String get search => 'সন্ধান করুন...';
	@override String get cancel => 'বাতিল';
	@override String get save => 'সংরক্ষণ';
	@override String get confirm => 'নিশ্চিত করুন';
	@override String get loading => 'লোড হচ্ছে...';
	@override String get error => 'কিছু ভুল হয়েছে';
	@override String get selectLanguage => 'ভাষা নির্বাচন করুন';
	@override String get nativeLanguage => 'মাতৃভাষা';
	@override String get dynamicTranslation => 'অনুবাদ করা হচ্ছে...';
	@override String get close => 'বন্ধ';
	@override String get back => 'ফিরে যান';
	@override String get details => 'বিবরণ';
	@override String get status => 'অবস্থা';
	@override String get view => 'দেখুন';
	@override String get submit => 'জমা দিন';
}

/// The flat map containing all translations for locale <bn>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsBn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appName' => 'PassionRide',
			'nav.home' => 'হোম',
			'nav.rides' => 'রাইড',
			'nav.wallet' => 'ওয়ালেট',
			'nav.provider' => 'প্রোভাইডার',
			'nav.profile' => 'প্রোফাইল',
			'nav.search' => 'সন্ধান',
			'nav.bookings' => 'বুকিং',
			'nav.chat' => 'চ্যাট',
			'nav.inbox' => 'ইনবক্স',
			'nav.saved' => 'সংরক্ষিত',
			'nav.host' => 'হোস্ট',
			'nav.earnings' => 'আয়',
			'home.heroTag' => 'P2P কাইনেটিক মার্কেটপ্লেস',
			'home.heroTitle' => 'আপনার পরবর্তী রাইড খুঁজুন বা গাইডেড ট্যুরে যোগ দিন',
			'home.searchPlaceholder' => 'শহর, গাড়ির মডেল বা গন্তব্য অনুসন্ধান করুন...',
			'home.exploreVehicles' => 'যানবাহন দেখুন',
			'home.guidedTours' => 'গাইডেড গ্রুপ ট্যুর',
			'home.featuredRides' => 'বিশেষ যানবাহন রেন্টাল',
			'home.popularTours' => 'জনপ্রিয় গাইডেড অভিযান',
			'home.trustMarketplace' => 'কাইনেটিক ট্রাস্ট ও যাচাইকৃত হোস্ট',
			'home.viewAll' => 'সব দেখুন',
			'home.nearYou' => 'আপনার কাছাকাছি',
			'home.perDay' => '/ দিন',
			'home.perPerson' => '/ জন',
			'search.title' => 'যানবাহন ও ট্যুর অনুসন্ধান করুন',
			'search.filter' => 'ফিল্টার',
			'search.location' => 'অবস্থান',
			'search.priceRange' => 'মূল্যের পরিসীমা',
			'search.vehicleType' => 'যানবাহনের ধরন',
			'search.allTypes' => 'সব ধরন',
			'search.cars' => 'গাড়ি',
			'search.bikes' => 'বাইসাইকেল ও বাইক',
			'search.scooters' => 'স্কুটার ও ইভি',
			'search.tours' => 'গাইডেড ট্যুর',
			'search.resultsFound' => 'ফলাফল পাওয়া গেছে',
			'search.noResults' => 'কোন ফলাফল পাওয়া যায়নি',
			'search.resetFilters' => 'ফিল্টার রিসেট করুন',
			'vehicle.details' => 'যানবাহনের বিবরণ',
			'vehicle.specs' => 'স্পেসিফিকেশন',
			'vehicle.pricePerDay' => 'দৈনিক মূল্য',
			'vehicle.bookNow' => 'এখনই বুক করুন',
			'vehicle.keylessUnlock' => 'IoT কি-লেস আনলক অন্তর্ভুক্ত',
			'vehicle.features' => 'যানবাহনের বৈশিষ্ট্য',
			'vehicle.hostInfo' => 'হোস্ট তথ্য',
			'vehicle.locationMap' => 'পিকআপ এবং ড্রপঅফ স্থান',
			'vehicle.reviews' => 'রিভিউ এবং রেটিং',
			'vehicle.rating' => 'রেটিং',
			'vehicle.transmission' => 'ট্রান্সমিশন',
			'vehicle.fuelType' => 'জ্বালানি / ইভি ধরন',
			'vehicle.seats' => 'সিট',
			'tours.guidedTrip' => 'গাইডেড গ্রুপ ট্যুর',
			'tours.itinerary' => 'ট্যুর ভ্রমণসূচী',
			'tours.duration' => 'সময়কাল',
			'tours.groupSize' => 'সর্বোচ্চ গ্রুপ আকার',
			'tours.includedServices' => 'অন্তর্ভুক্ত পরিষেবা',
			'tours.joinTour' => 'অভিযানে যোগ দিন',
			'tours.hostGuide' => 'ট্যুর গাইড / লিডার',
			'tours.highlights' => 'প্রধান আকর্ষণ',
			'tours.departureDate' => 'যাত্রার তারিখ',
			'tours.meetingPoint' => 'সাক্ষাতের স্থান',
			'booking.verification' => 'বুকিং যাচাইকরণ এবং পিন',
			'booking.checkout' => 'পেমেন্ট চেকআউট',
			'booking.payment' => 'পেমেন্ট সম্পন্ন করুন',
			'booking.totalAmount' => 'মোট পরিমাণ',
			'booking.payWithRazorpay' => 'Razorpay / UPI এর মাধ্যমে দিন',
			'booking.pinVerification' => 'আনলক পিন যাচাই করুন',
			'booking.confirmBooking' => 'নিশ্চিত করুন ও বুক করুন',
			'booking.success' => 'বুকিং সফলভাবে নিশ্চিত হয়েছে!',
			'booking.status' => 'বুকিং এর অবস্থা',
			'booking.active' => 'সক্রিয়',
			'booking.completed' => 'সম্পন্ন',
			'booking.cancelled' => 'বাতিল',
			'provider.fleetDashboard' => 'হোস্ট ফ্লিট ড্যাশবোর্ড',
			'provider.earnings' => 'আর্থিক উপার্জন',
			'provider.addVehicle' => 'নতুন গাড়ি নিবন্ধন করুন',
			'provider.addTour' => 'গাইডেড ট্যুর প্রকাশ করুন',
			'provider.registerListing' => 'লিস্টিং নিবন্ধন করুন',
			'provider.activeListings' => 'সক্রিয় যানবাহন লিস্টিং',
			'provider.monthlyRevenue' => 'মাসিক আয়',
			'provider.manageFleet' => 'লিস্টিং পরিচালনা করুন',
			'profile.title' => 'আমার প্রোফাইল',
			'profile.personalInfo' => 'ব্যক্তিগত তথ্য',
			'profile.vehicleInfo' => 'যানবাহনের বিবরণ',
			'profile.driverLicense' => 'ড্রাইভিং লাইসেন্স',
			'profile.language' => 'অ্যাপের ভাষা',
			'profile.settings' => 'সেটিংস',
			'profile.logout' => 'লগ আউট',
			'profile.editProfile' => 'প্রোফাইল সম্পাদনা করুন',
			'profile.verified' => 'যাচাইকৃত',
			'profile.accountPreferences' => 'অ্যাকাউন্ট ও পছন্দসমূহ',
			'profile.darkMode' => 'ডার্ক মোড থিম',
			'profile.darkModeSubtitle' => 'ডার্ক বা লাইট অ্যাপ থিম পরিবর্তন করুন',
			'profile.documents' => 'নথিপত্র ও লাইসেন্স',
			'profile.documentsSubtitle' => 'ড্রাইভিং লাইসেন্স, আধার কার্ড এবং সরকারি আইডি',
			'profile.trustReputation' => 'কাইনেটিক ট্রাস্ট সুনাম',
			'profile.trustReputationSubtitle' => 'ট্রাস্ট স্কোর ব্রেকডাউন এবং ব্যাজ দেখুন',
			'profile.passwordReset' => 'পাসওয়ার্ড রিসেট',
			'profile.passwordResetSubtitle' => 'নিরাপত্তা পাসওয়ার্ড রিসেট ইমেল পাঠান',
			'profile.financials' => 'প্রোভাইডার আর্থিক হিসাব',
			'profile.financialsSubtitle' => 'উপার্জন, পেআউট এবং ব্যাংকিং তথ্য',
			'profile.aiGenerator' => 'এআই ট্যুর জেনারেটর',
			'profile.aiGeneratorSubtitle' => 'এআই কো-পাইলটের সাহায্যে সফরসূচি তৈরি করুন',
			'profile.inAppPortal' => 'ইন-অ্যাপ ওয়েব পোর্টাল',
			'profile.inAppPortalSubtitle' => 'যেকোনো বাহ্যিক ওয়েবসাইট সরাসরি দেখুন',
			'profile.feedback' => 'মতামত জানান',
			'profile.feedbackSubtitle' => 'অ্যাপ অভিজ্ঞতা পর্যালোচনা বা বাগ জমা দিন',
			'profile.feedbackInsights' => 'ফিডব্যাক এবং ট্রাস্ট ইনসাইট',
			'profile.feedbackInsightsSubtitle' => 'হোস্টের পর্যালোচনার বিশ্লেষণ দেখুন',
			'profile.switchRole' => 'ভূমিকা পরিবর্তন করুন',
			'telematics.ioTHub' => 'যানবাহন টেলিমেটিক্স হাব',
			'telematics.remoteLock' => 'রিমোট লক / আনলক',
			'telematics.engineStatus' => 'ইঞ্জিনের অবস্থা',
			'telematics.batteryLevel' => 'ব্যাটারির মাত্রা',
			'telematics.gpsTracking' => 'লাইভ জিপিএস ট্র্যাকিং',
			'telematics.speedAlert' => 'গতি সতর্কতা সিস্টেম',
			'documents.identityVerification' => 'পরিচয় যাচাইকরণ',
			'documents.driverLicense' => 'ড্রাইভিং লাইসেন্স',
			'documents.governmentId' => 'সরকারি পরিচয়পত্র',
			'documents.complianceStatus' => 'সম্মতি অবস্থা',
			'documents.uploadDoc' => 'নথি আপলোড করুন',
			'common.welcome' => 'স্বাগতম!',
			'common.search' => 'সন্ধান করুন...',
			'common.cancel' => 'বাতিল',
			'common.save' => 'সংরক্ষণ',
			'common.confirm' => 'নিশ্চিত করুন',
			'common.loading' => 'লোড হচ্ছে...',
			'common.error' => 'কিছু ভুল হয়েছে',
			'common.selectLanguage' => 'ভাষা নির্বাচন করুন',
			'common.nativeLanguage' => 'মাতৃভাষা',
			'common.dynamicTranslation' => 'অনুবাদ করা হচ্ছে...',
			'common.close' => 'বন্ধ',
			'common.back' => 'ফিরে যান',
			'common.details' => 'বিবরণ',
			'common.status' => 'অবস্থা',
			'common.view' => 'দেখুন',
			'common.submit' => 'জমা দিন',
			_ => null,
		};
	}
}
