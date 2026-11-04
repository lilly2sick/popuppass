// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pop-Up Pass';

  @override
  String get tabHome => 'Home';

  @override
  String get tabShop => 'Shop';

  @override
  String get tabSell => 'Sell';

  @override
  String get tabCreate => 'Create';

  @override
  String get tabInsights => 'Insights';

  @override
  String get loaderSettingUp => 'Setting up your table';

  @override
  String get loaderError => 'Something went wrong starting up. Restart the app.';

  @override
  String get homeEyebrow => 'Made for the makers';

  @override
  String get homeTitle => 'Hey, maker.';

  @override
  String get homeSearchHint => 'Search items, sales, events';

  @override
  String get homeOpenTable => 'Open table';

  @override
  String get homeStatGross => 'Gross';

  @override
  String get homeStatSold => 'Sold';

  @override
  String get homeStatLow => 'Low';

  @override
  String get homeItemOne => 'item';

  @override
  String get homeItemMany => 'items';

  @override
  String homeAlmostGone(String name) {
    return '$name is almost gone.';
  }

  @override
  String homeLeft(int count) {
    return '$count left.';
  }

  @override
  String get homeFanFavorites => 'Fan favorites';

  @override
  String homeSoldCount(int count) {
    return '$count sold';
  }

  @override
  String get homeDayTitle => 'A good day, in four small steps';

  @override
  String get homeStepBeforeTag => 'Night before';

  @override
  String get homeStepBeforeTitle => 'Price and count';

  @override
  String homeStepBeforeText(int count) {
    return 'Prices set, $count items stocked.';
  }

  @override
  String get homeStepNowTag => 'At the table';

  @override
  String get homeStepNowTitle => 'Tap to sell';

  @override
  String homeStepNowText(int count) {
    return '$count sales so far. You are here.';
  }

  @override
  String get homeStepPostTag => 'Between rushes';

  @override
  String get homeStepPostTitle => 'Post a best seller';

  @override
  String homeStepPostText(String name) {
    return '$name is ready to share.';
  }

  @override
  String get homeStepAfterTag => 'After the con';

  @override
  String get homeStepAfterTitle => 'See what moved';

  @override
  String get homeStepAfterText => 'Recap and restock ideas.';

  @override
  String get homeExperiment => 'Room to experiment';

  @override
  String get homeCaughtUpTitle => 'All caught up';

  @override
  String get homeCaughtUpMessage => 'New ideas land when the trend board refreshes.';

  @override
  String get homeRising => 'Rising';

  @override
  String get homeNotForMe => 'Not for me';

  @override
  String get homeTryIt => 'Try it';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsFreePass => 'Free pass';

  @override
  String get settingsPro => 'You are on Pro';

  @override
  String get settingsFreeBody =>
      'Everything stays on this phone. Pro adds cloud backup, AI captions, and PDF and Excel exports.';

  @override
  String get settingsProBody => 'Cloud backup, AI captions and summaries, PDF and Excel exports.';

  @override
  String get settingsGoPro => 'Go Pro';

  @override
  String get settingsRestore => 'Restore purchases';

  @override
  String get settingsHaptics => 'Haptics';

  @override
  String get settingsHapticStrength => 'Haptic strength';

  @override
  String settingsCardReader(String name) {
    return 'Card reader: $name';
  }

  @override
  String get settingsConnect => 'Connect';

  @override
  String get settingsDisconnect => 'Disconnect';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteSubtitle => 'Deletes your cloud backup. Data on this phone stays.';

  @override
  String get settingsDeleteConfirmTitle => 'Delete account?';

  @override
  String get settingsDeleteConfirmBody => 'Your cloud backup is removed for good.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';
}
