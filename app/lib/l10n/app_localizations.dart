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

  /// No description provided for @homeHeroGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hey, maker.\nYour table looks good.'**
  String get homeHeroGreeting;

  /// No description provided for @homeHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s the little picture so far.'**
  String get homeHeroSubtitle;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeNotSoPopular.
  ///
  /// In en, this message translates to:
  /// **'Not so popular'**
  String get homeNotSoPopular;

  /// No description provided for @homeAfterCost.
  ///
  /// In en, this message translates to:
  /// **'{amount} after cost'**
  String homeAfterCost(String amount);

  /// No description provided for @homeJustNow.
  ///
  /// In en, this message translates to:
  /// **'JUST NOW'**
  String get homeJustNow;

  /// No description provided for @homeGoToMyTable.
  ///
  /// In en, this message translates to:
  /// **'Go to my table'**
  String get homeGoToMyTable;

  /// No description provided for @homeRestockNote.
  ///
  /// In en, this message translates to:
  /// **'Restock note'**
  String get homeRestockNote;

  /// No description provided for @homeTrendMoodboard.
  ///
  /// In en, this message translates to:
  /// **'[TREND MOODBOARD]'**
  String get homeTrendMoodboard;

  /// No description provided for @homeDeckCount.
  ///
  /// In en, this message translates to:
  /// **'{index} OF {total}'**
  String homeDeckCount(int index, int total);

  /// No description provided for @splashDots.
  ///
  /// In en, this message translates to:
  /// **'Setting up your table'**
  String get splashDots;

  /// No description provided for @shopEyebrow.
  ///
  /// In en, this message translates to:
  /// **'{count} items / {units} in stock'**
  String shopEyebrow(int count, int units);

  /// No description provided for @shopTitle.
  ///
  /// In en, this message translates to:
  /// **'Your shop'**
  String get shopTitle;

  /// No description provided for @shopSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search items, tags, SKU'**
  String get shopSearchHint;

  /// No description provided for @shopAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get shopAddItem;

  /// No description provided for @shopFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get shopFilterAll;

  /// No description provided for @shopFilterLow.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get shopFilterLow;

  /// No description provided for @shopFilterMargin.
  ///
  /// In en, this message translates to:
  /// **'Best margin'**
  String get shopFilterMargin;

  /// No description provided for @shopStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Start your shop'**
  String get shopStartTitle;

  /// No description provided for @shopStartMessage.
  ///
  /// In en, this message translates to:
  /// **'Add your first item or import a CSV.'**
  String get shopStartMessage;

  /// No description provided for @shopEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get shopEmptyTitle;

  /// No description provided for @shopEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No items match this filter.'**
  String get shopEmptyMessage;

  /// No description provided for @shopImportCsv.
  ///
  /// In en, this message translates to:
  /// **'Import from CSV'**
  String get shopImportCsv;

  /// No description provided for @shopMarginPct.
  ///
  /// In en, this message translates to:
  /// **'{pct}% margin'**
  String shopMarginPct(int pct);

  /// No description provided for @shopInStock.
  ///
  /// In en, this message translates to:
  /// **'{count} in stock'**
  String shopInStock(int count);

  /// No description provided for @shopLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String shopLeft(int count);

  /// No description provided for @editorNewItem.
  ///
  /// In en, this message translates to:
  /// **'New item'**
  String get editorNewItem;

  /// No description provided for @editorEditItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get editorEditItem;

  /// No description provided for @editorName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get editorName;

  /// No description provided for @editorMaterialsPerItem.
  ///
  /// In en, this message translates to:
  /// **'Materials per item (\$)'**
  String get editorMaterialsPerItem;

  /// No description provided for @editorMinutesToMake.
  ///
  /// In en, this message translates to:
  /// **'Minutes to make'**
  String get editorMinutesToMake;

  /// No description provided for @editorPriceSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Try {low} to {high}.'**
  String editorPriceSuggestion(String low, String high);

  /// No description provided for @editorPriceSuggestionBreakEven.
  ///
  /// In en, this message translates to:
  /// **' Sell {units} to cover your booth.'**
  String editorPriceSuggestionBreakEven(int units);

  /// No description provided for @editorPrice.
  ///
  /// In en, this message translates to:
  /// **'Price (\$)'**
  String get editorPrice;

  /// No description provided for @editorStartingStock.
  ///
  /// In en, this message translates to:
  /// **'Starting stock'**
  String get editorStartingStock;

  /// No description provided for @editorAddStock.
  ///
  /// In en, this message translates to:
  /// **'Add stock'**
  String get editorAddStock;

  /// No description provided for @editorSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get editorSave;

  /// No description provided for @editorDeleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get editorDeleteItem;

  /// No description provided for @sellTitle.
  ///
  /// In en, this message translates to:
  /// **'Your table, in a tap.'**
  String get sellTitle;

  /// No description provided for @sellSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search your items'**
  String get sellSearchHint;

  /// No description provided for @sellBackToSingle.
  ///
  /// In en, this message translates to:
  /// **'Back to single item'**
  String get sellBackToSingle;

  /// No description provided for @sellZoomToGrid.
  ///
  /// In en, this message translates to:
  /// **'Zoom out to grid'**
  String get sellZoomToGrid;

  /// No description provided for @sellAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get sellAddItem;

  /// No description provided for @sellRemoveOneSale.
  ///
  /// In en, this message translates to:
  /// **'Remove one {name} sale'**
  String sellRemoveOneSale(String name);

  /// No description provided for @sellSellOne.
  ///
  /// In en, this message translates to:
  /// **'Sell one {name}'**
  String sellSellOne(String name);

  /// No description provided for @sellSoldOut.
  ///
  /// In en, this message translates to:
  /// **'Sold out'**
  String get sellSoldOut;

  /// No description provided for @sellOneSold.
  ///
  /// In en, this message translates to:
  /// **'+1 sold'**
  String get sellOneSold;

  /// No description provided for @sellMinus1.
  ///
  /// In en, this message translates to:
  /// **'-1'**
  String get sellMinus1;

  /// No description provided for @sellNoItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'No items yet'**
  String get sellNoItemsTitle;

  /// No description provided for @sellNoItemsMessage.
  ///
  /// In en, this message translates to:
  /// **'Add your first item with the + button.'**
  String get sellNoItemsMessage;

  /// No description provided for @sellNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No match'**
  String get sellNoMatchTitle;

  /// No description provided for @sellNoMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches \"{query}\"'**
  String sellNoMatchMessage(String query);

  /// No description provided for @sellPaidWith.
  ///
  /// In en, this message translates to:
  /// **'Paid with {method}'**
  String sellPaidWith(String method);

  /// No description provided for @sellGross.
  ///
  /// In en, this message translates to:
  /// **'{amount} gross'**
  String sellGross(String amount);

  /// No description provided for @sellPosition.
  ///
  /// In en, this message translates to:
  /// **'{index} / {total}'**
  String sellPosition(int index, int total);

  /// No description provided for @sellOpenItem.
  ///
  /// In en, this message translates to:
  /// **'Open {name}, {left} left, {sold} sold'**
  String sellOpenItem(String name, int left, int sold);

  /// No description provided for @sellSoldCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sold'**
  String sellSoldCount(int count);

  /// No description provided for @sellPriceSold.
  ///
  /// In en, this message translates to:
  /// **'{price} / {count} sold'**
  String sellPriceSold(String price, int count);

  /// No description provided for @createTitle.
  ///
  /// In en, this message translates to:
  /// **'Make a little noise.'**
  String get createTitle;

  /// No description provided for @createSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search items to post'**
  String get createSearchHint;

  /// No description provided for @createPickItem.
  ///
  /// In en, this message translates to:
  /// **'Pick an item'**
  String get createPickItem;

  /// No description provided for @createBackSoon.
  ///
  /// In en, this message translates to:
  /// **'{name} is back.'**
  String createBackSoon(String name);

  /// No description provided for @createDefaultShopName.
  ///
  /// In en, this message translates to:
  /// **'My shop'**
  String get createDefaultShopName;

  /// No description provided for @createCaptionLabel.
  ///
  /// In en, this message translates to:
  /// **'CAPTION'**
  String get createCaptionLabel;

  /// No description provided for @createUseMine.
  ///
  /// In en, this message translates to:
  /// **'Use mine'**
  String get createUseMine;

  /// No description provided for @createAiVersion.
  ///
  /// In en, this message translates to:
  /// **'AI version'**
  String get createAiVersion;

  /// No description provided for @createCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Pick an item to start a caption'**
  String get createCaptionHint;

  /// No description provided for @createShareOrSave.
  ///
  /// In en, this message translates to:
  /// **'Share or save'**
  String get createShareOrSave;

  /// No description provided for @createShareShape.
  ///
  /// In en, this message translates to:
  /// **'Share {noun}'**
  String createShareShape(String noun);

  /// No description provided for @createSavedToPhotos.
  ///
  /// In en, this message translates to:
  /// **'Saved {width} x {height} PNG to Photos'**
  String createSavedToPhotos(int width, int height);

  /// No description provided for @createSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Allow Photos access in Settings.'**
  String get createSaveFailed;

  /// No description provided for @createShapePost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get createShapePost;

  /// No description provided for @createShapeStory.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get createShapeStory;

  /// No description provided for @createShapeWide.
  ///
  /// In en, this message translates to:
  /// **'Wide'**
  String get createShapeWide;

  /// No description provided for @createNounPost.
  ///
  /// In en, this message translates to:
  /// **'post'**
  String get createNounPost;

  /// No description provided for @createNounStory.
  ///
  /// In en, this message translates to:
  /// **'story'**
  String get createNounStory;

  /// No description provided for @createNounWide.
  ///
  /// In en, this message translates to:
  /// **'wide post'**
  String get createNounWide;

  /// No description provided for @createTargetPng.
  ///
  /// In en, this message translates to:
  /// **'Save as PNG'**
  String get createTargetPng;

  /// No description provided for @createTargetInstagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get createTargetInstagram;

  /// No description provided for @createTargetFacebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get createTargetFacebook;

  /// No description provided for @createTargetLinkedin.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn'**
  String get createTargetLinkedin;

  /// No description provided for @createTargetMore.
  ///
  /// In en, this message translates to:
  /// **'More apps'**
  String get createTargetMore;

  /// No description provided for @createTargetMoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Messages, Shopify, Etsy and others'**
  String get createTargetMoreSubtitle;

  /// No description provided for @createTargetPngSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{width} x {height} to Photos'**
  String createTargetPngSubtitle(int width, int height);

  /// No description provided for @createTargetSizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{width} x {height}'**
  String createTargetSizeSubtitle(int width, int height);

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Look what you did.'**
  String get insightsTitle;

  /// No description provided for @insightsExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get insightsExport;

  /// No description provided for @insightsExportPro.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get insightsExportPro;

  /// No description provided for @insightsPdfXlsxLocked.
  ///
  /// In en, this message translates to:
  /// **'PDF and Excel exports are part of Pro.'**
  String get insightsPdfXlsxLocked;

  /// No description provided for @insightsNetProfit.
  ///
  /// In en, this message translates to:
  /// **'Net profit'**
  String get insightsNetProfit;

  /// No description provided for @insightsNetCaption.
  ///
  /// In en, this message translates to:
  /// **'{gross} gross, {cost} cost, {booth} booth. {units} sold.'**
  String insightsNetCaption(String gross, String cost, String booth, int units);

  /// No description provided for @insightsProfitByItem.
  ///
  /// In en, this message translates to:
  /// **'Profit by item'**
  String get insightsProfitByItem;

  /// No description provided for @insightsHowTheyPaid.
  ///
  /// In en, this message translates to:
  /// **'How they paid'**
  String get insightsHowTheyPaid;

  /// No description provided for @insightsYourRecap.
  ///
  /// In en, this message translates to:
  /// **'YOUR RECAP'**
  String get insightsYourRecap;

  /// No description provided for @insightsReportTitle.
  ///
  /// In en, this message translates to:
  /// **'{event} report'**
  String insightsReportTitle(String event);

  /// No description provided for @insightsAllSales.
  ///
  /// In en, this message translates to:
  /// **'All sales'**
  String get insightsAllSales;

  /// No description provided for @insightsThisEvent.
  ///
  /// In en, this message translates to:
  /// **'this event'**
  String get insightsThisEvent;

  /// No description provided for @insightsUnitsOverProfit.
  ///
  /// In en, this message translates to:
  /// **'{units} / {profit}'**
  String insightsUnitsOverProfit(int units, String profit);

  /// No description provided for @insightsMethodAmount.
  ///
  /// In en, this message translates to:
  /// **'{method} {amount}'**
  String insightsMethodAmount(String method, String amount);

  /// No description provided for @eventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your events'**
  String get eventsTitle;

  /// No description provided for @eventsSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get eventsSettingsTooltip;

  /// No description provided for @eventsConsNearYou.
  ///
  /// In en, this message translates to:
  /// **'Cons near you'**
  String get eventsConsNearYou;

  /// No description provided for @eventsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get eventsAdd;

  /// No description provided for @eventsPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Distance is worked out on your phone. Your location is never sent anywhere.'**
  String get eventsPrivacyNote;

  /// No description provided for @eventsNew.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get eventsNew;

  /// No description provided for @eventsImportIcs.
  ///
  /// In en, this message translates to:
  /// **'Import .ics'**
  String get eventsImportIcs;

  /// No description provided for @eventsExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get eventsExport;

  /// No description provided for @eventsNameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Event name'**
  String get eventsNameDialogTitle;

  /// No description provided for @eventsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get eventsSave;

  /// No description provided for @eventsLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get eventsLive;

  /// No description provided for @searchHintDefault.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHintDefault;

  /// No description provided for @searchResultsFor.
  ///
  /// In en, this message translates to:
  /// **'Results for \"{query}\"'**
  String searchResultsFor(String query);

  /// No description provided for @searchNothingFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get searchNothingFoundTitle;

  /// No description provided for @searchNothingFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a shorter word.'**
  String get searchNothingFoundMessage;

  /// No description provided for @searchItemsHeader.
  ///
  /// In en, this message translates to:
  /// **'ITEMS'**
  String get searchItemsHeader;

  /// No description provided for @searchEventsHeader.
  ///
  /// In en, this message translates to:
  /// **'EVENTS'**
  String get searchEventsHeader;

  /// No description provided for @searchLeftPrice.
  ///
  /// In en, this message translates to:
  /// **'{left} left  /  {price}'**
  String searchLeftPrice(int left, String price);

  /// No description provided for @pupGreetingTitle.
  ///
  /// In en, this message translates to:
  /// **'Hey, maker. I\'m PUP.'**
  String get pupGreetingTitle;

  /// No description provided for @pupNeedHand.
  ///
  /// In en, this message translates to:
  /// **'Need a hand?'**
  String get pupNeedHand;

  /// No description provided for @pupCornerHint.
  ///
  /// In en, this message translates to:
  /// **'I live in the corner. Tap me any time you get stuck.'**
  String get pupCornerHint;

  /// No description provided for @pupLetsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get pupLetsGo;

  /// No description provided for @pupAskPup.
  ///
  /// In en, this message translates to:
  /// **'Ask PUP'**
  String get pupAskPup;

  /// No description provided for @pupFaqOfflineQ.
  ///
  /// In en, this message translates to:
  /// **'Does it work with no signal?'**
  String get pupFaqOfflineQ;

  /// No description provided for @pupFaqOfflineA.
  ///
  /// In en, this message translates to:
  /// **'Yes. Everything saves on your phone first. Pro backs it up when you are back online.'**
  String get pupFaqOfflineA;

  /// No description provided for @pupFaqDoubleTapQ.
  ///
  /// In en, this message translates to:
  /// **'I tapped +1 twice by accident'**
  String get pupFaqDoubleTapQ;

  /// No description provided for @pupFaqDoubleTapA.
  ///
  /// In en, this message translates to:
  /// **'Tap -1 on the same item. It removes the last sale and puts the item back in stock.'**
  String get pupFaqDoubleTapA;

  /// No description provided for @pupFaqAddEventQ.
  ///
  /// In en, this message translates to:
  /// **'How do I add an event?'**
  String get pupFaqAddEventQ;

  /// No description provided for @pupFaqAddEventA.
  ///
  /// In en, this message translates to:
  /// **'Tap the pass at the top of any screen, then New event, Import .ics, or pick a con near you.'**
  String get pupFaqAddEventA;

  /// No description provided for @pupFaqDataQ.
  ///
  /// In en, this message translates to:
  /// **'Where is my data?'**
  String get pupFaqDataQ;

  /// No description provided for @pupFaqDataA.
  ///
  /// In en, this message translates to:
  /// **'On this phone only, unless you turn on Pro backup. We never sell your sales data.'**
  String get pupFaqDataA;

  /// No description provided for @pupFaqProQ.
  ///
  /// In en, this message translates to:
  /// **'What does Pro add?'**
  String get pupFaqProQ;

  /// No description provided for @pupFaqProA.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup, AI captions and recaps, card reader sync, PDF and Excel exports.'**
  String get pupFaqProA;

  /// No description provided for @connectionOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline, saved on phone'**
  String get connectionOffline;

  /// No description provided for @connectionSavedOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Saved on phone'**
  String get connectionSavedOnPhone;

  /// No description provided for @connectionSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get connectionSynced;

  /// No description provided for @connectionSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing {count}'**
  String connectionSyncing(int count);

  /// No description provided for @eventBarNoEvent.
  ///
  /// In en, this message translates to:
  /// **'No event yet'**
  String get eventBarNoEvent;

  /// No description provided for @eventBarAddOne.
  ///
  /// In en, this message translates to:
  /// **'Add one'**
  String get eventBarAddOne;

  /// No description provided for @eventBarLiveDay.
  ///
  /// In en, this message translates to:
  /// **'Live day {day}'**
  String eventBarLiveDay(int day);

  /// No description provided for @eventBarInDays.
  ///
  /// In en, this message translates to:
  /// **'In {days} d'**
  String eventBarInDays(int days);

  /// No description provided for @eventBarEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get eventBarEnded;

  /// No description provided for @eventBarOpenEvents.
  ///
  /// In en, this message translates to:
  /// **'Open events. {name}'**
  String eventBarOpenEvents(String name);

  /// No description provided for @eventBarPass.
  ///
  /// In en, this message translates to:
  /// **'PASS'**
  String get eventBarPass;

  /// No description provided for @eventBarNetToday.
  ///
  /// In en, this message translates to:
  /// **'NET TODAY'**
  String get eventBarNetToday;

  /// No description provided for @paymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentCash;

  /// No description provided for @paymentCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get paymentCard;

  /// No description provided for @paymentZelle.
  ///
  /// In en, this message translates to:
  /// **'Zelle'**
  String get paymentZelle;

  /// No description provided for @paymentVenmo.
  ///
  /// In en, this message translates to:
  /// **'Venmo'**
  String get paymentVenmo;

  /// No description provided for @paymentCashapp.
  ///
  /// In en, this message translates to:
  /// **'Cash App'**
  String get paymentCashapp;

  /// No description provided for @paymentPaypal.
  ///
  /// In en, this message translates to:
  /// **'PayPal'**
  String get paymentPaypal;

  /// No description provided for @paymentOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get paymentOther;

  /// No description provided for @exportFormatCsv.
  ///
  /// In en, this message translates to:
  /// **'CSV'**
  String get exportFormatCsv;

  /// No description provided for @exportFormatPng.
  ///
  /// In en, this message translates to:
  /// **'PNG'**
  String get exportFormatPng;

  /// No description provided for @exportFormatXlsx.
  ///
  /// In en, this message translates to:
  /// **'Excel'**
  String get exportFormatXlsx;

  /// No description provided for @exportFormatPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF report'**
  String get exportFormatPdf;

  /// No description provided for @aiPendingCaption.
  ///
  /// In en, this message translates to:
  /// **'AI VERSION WRITING. KEEP WORKING.'**
  String get aiPendingCaption;

  /// No description provided for @asciiFreeModeNote.
  ///
  /// In en, this message translates to:
  /// **'Free mode keeps your data on this phone. We never sell your sales data.'**
  String get asciiFreeModeNote;

  /// No description provided for @exportColSoldAt.
  ///
  /// In en, this message translates to:
  /// **'Sold at'**
  String get exportColSoldAt;

  /// No description provided for @exportColItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get exportColItem;

  /// No description provided for @exportColQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get exportColQty;

  /// No description provided for @exportColUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get exportColUnitPrice;

  /// No description provided for @exportColUnitCost.
  ///
  /// In en, this message translates to:
  /// **'Unit cost'**
  String get exportColUnitCost;

  /// No description provided for @exportColPaidWith.
  ///
  /// In en, this message translates to:
  /// **'Paid with'**
  String get exportColPaidWith;

  /// No description provided for @exportColSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get exportColSource;

  /// No description provided for @passHeaderLeft.
  ///
  /// In en, this message translates to:
  /// **'POP UP PASS'**
  String get passHeaderLeft;

  /// No description provided for @passHeaderRight.
  ///
  /// In en, this message translates to:
  /// **'NO. 1'**
  String get passHeaderRight;

  /// No description provided for @passRole.
  ///
  /// In en, this message translates to:
  /// **'MAKER'**
  String get passRole;

  /// No description provided for @passAccess.
  ///
  /// In en, this message translates to:
  /// **'ALL ACCESS'**
  String get passAccess;
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
