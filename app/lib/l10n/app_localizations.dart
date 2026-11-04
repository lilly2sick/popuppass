import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Pop-Up Pass'**
  String get appTitle;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get tabShop;

  /// No description provided for @tabSell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get tabSell;

  /// No description provided for @tabCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get tabCreate;

  /// No description provided for @tabInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get tabInsights;

  /// No description provided for @loaderSettingUp.
  ///
  /// In en, this message translates to:
  /// **'Setting up your table'**
  String get loaderSettingUp;

  /// No description provided for @loaderError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong starting up. Restart the app.'**
  String get loaderError;

  /// No description provided for @homeEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Made for the makers'**
  String get homeEyebrow;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Hey, maker.'**
  String get homeTitle;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search items, sales, events'**
  String get homeSearchHint;

  /// No description provided for @homeOpenTable.
  ///
  /// In en, this message translates to:
  /// **'Open table'**
  String get homeOpenTable;

  /// No description provided for @homeStatGross.
  ///
  /// In en, this message translates to:
  /// **'Gross'**
  String get homeStatGross;

  /// No description provided for @homeStatSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get homeStatSold;

  /// No description provided for @homeStatLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get homeStatLow;

  /// No description provided for @homeItemOne.
  ///
  /// In en, this message translates to:
  /// **'item'**
  String get homeItemOne;

  /// No description provided for @homeItemMany.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get homeItemMany;

  /// No description provided for @homeAlmostGone.
  ///
  /// In en, this message translates to:
  /// **'{name} is almost gone.'**
  String homeAlmostGone(String name);

  /// No description provided for @homeLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} left.'**
  String homeLeft(int count);

  /// No description provided for @homeFanFavorites.
  ///
  /// In en, this message translates to:
  /// **'Fan favorites'**
  String get homeFanFavorites;

  /// No description provided for @homeSoldCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sold'**
  String homeSoldCount(int count);

  /// No description provided for @homeDayTitle.
  ///
  /// In en, this message translates to:
  /// **'A good day, in four small steps'**
  String get homeDayTitle;

  /// No description provided for @homeStepBeforeTag.
  ///
  /// In en, this message translates to:
  /// **'Night before'**
  String get homeStepBeforeTag;

  /// No description provided for @homeStepBeforeTitle.
  ///
  /// In en, this message translates to:
  /// **'Price and count'**
  String get homeStepBeforeTitle;

  /// No description provided for @homeStepBeforeText.
  ///
  /// In en, this message translates to:
  /// **'Prices set, {count} items stocked.'**
  String homeStepBeforeText(int count);

  /// No description provided for @homeStepNowTag.
  ///
  /// In en, this message translates to:
  /// **'At the table'**
  String get homeStepNowTag;

  /// No description provided for @homeStepNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to sell'**
  String get homeStepNowTitle;

  /// No description provided for @homeStepNowText.
  ///
  /// In en, this message translates to:
  /// **'{count} sales so far. You are here.'**
  String homeStepNowText(int count);

  /// No description provided for @homeStepPostTag.
  ///
  /// In en, this message translates to:
  /// **'Between rushes'**
  String get homeStepPostTag;

  /// No description provided for @homeStepPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Post a best seller'**
  String get homeStepPostTitle;

  /// No description provided for @homeStepPostText.
  ///
  /// In en, this message translates to:
  /// **'{name} is ready to share.'**
  String homeStepPostText(String name);

  /// No description provided for @homeStepAfterTag.
  ///
  /// In en, this message translates to:
  /// **'After the con'**
  String get homeStepAfterTag;

  /// No description provided for @homeStepAfterTitle.
  ///
  /// In en, this message translates to:
  /// **'See what moved'**
  String get homeStepAfterTitle;

  /// No description provided for @homeStepAfterText.
  ///
  /// In en, this message translates to:
  /// **'Recap and restock ideas.'**
  String get homeStepAfterText;

  /// No description provided for @homeExperiment.
  ///
  /// In en, this message translates to:
  /// **'Room to experiment'**
  String get homeExperiment;

  /// No description provided for @homeCaughtUpTitle.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get homeCaughtUpTitle;

  /// No description provided for @homeCaughtUpMessage.
  ///
  /// In en, this message translates to:
  /// **'New ideas land when the trend board refreshes.'**
  String get homeCaughtUpMessage;

  /// No description provided for @homeRising.
  ///
  /// In en, this message translates to:
  /// **'Rising'**
  String get homeRising;

  /// No description provided for @homeNotForMe.
  ///
  /// In en, this message translates to:
  /// **'Not for me'**
  String get homeNotForMe;

  /// No description provided for @homeTryIt.
  ///
  /// In en, this message translates to:
  /// **'Try it'**
  String get homeTryIt;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsFreePass.
  ///
  /// In en, this message translates to:
  /// **'Free pass'**
  String get settingsFreePass;

  /// No description provided for @settingsPro.
  ///
  /// In en, this message translates to:
  /// **'You are on Pro'**
  String get settingsPro;

  /// No description provided for @settingsFreeBody.
  ///
  /// In en, this message translates to:
  /// **'Everything stays on this phone. Pro adds cloud backup, AI captions, and PDF and Excel exports.'**
  String get settingsFreeBody;

  /// No description provided for @settingsProBody.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup, AI captions and summaries, PDF and Excel exports.'**
  String get settingsProBody;

  /// No description provided for @settingsGoPro.
  ///
  /// In en, this message translates to:
  /// **'Go Pro'**
  String get settingsGoPro;

  /// No description provided for @settingsRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get settingsRestore;

  /// No description provided for @settingsHaptics.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get settingsHaptics;

  /// No description provided for @settingsHapticStrength.
  ///
  /// In en, this message translates to:
  /// **'Haptic strength'**
  String get settingsHapticStrength;

  /// No description provided for @settingsCardReader.
  ///
  /// In en, this message translates to:
  /// **'Card reader: {name}'**
  String settingsCardReader(String name);

  /// No description provided for @settingsConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get settingsConnect;

  /// No description provided for @settingsDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get settingsDisconnect;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deletes your cloud backup. Data on this phone stays.'**
  String get settingsDeleteSubtitle;

  /// No description provided for @settingsDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get settingsDeleteConfirmTitle;

  /// No description provided for @settingsDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your cloud backup is removed for good.'**
  String get settingsDeleteConfirmBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
