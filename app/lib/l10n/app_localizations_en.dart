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

  @override
  String get homeHeroGreeting => 'Hey, maker.\nYour table looks good.';

  @override
  String get homeHeroSubtitle => 'Here\'s the little picture so far.';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeNotSoPopular => 'Not so popular';

  @override
  String homeAfterCost(String amount) {
    return '$amount after cost';
  }

  @override
  String get homeJustNow => 'JUST NOW';

  @override
  String get homeGoToMyTable => 'Go to my table';

  @override
  String get homeRestockNote => 'Restock note';

  @override
  String get homeTrendMoodboard => '[TREND MOODBOARD]';

  @override
  String homeDeckCount(int index, int total) {
    return '$index OF $total';
  }

  @override
  String get splashDots => 'Setting up your table';

  @override
  String shopEyebrow(int count, int units) {
    return '$count items / $units in stock';
  }

  @override
  String get shopTitle => 'Your shop';

  @override
  String get shopSearchHint => 'Search items, tags, SKU';

  @override
  String get shopAddItem => 'Add item';

  @override
  String get shopFilterAll => 'All';

  @override
  String get shopFilterLow => 'Low stock';

  @override
  String get shopFilterMargin => 'Best margin';

  @override
  String get shopStartTitle => 'Start your shop';

  @override
  String get shopStartMessage => 'Add your first item or import a CSV.';

  @override
  String get shopEmptyTitle => 'Nothing here';

  @override
  String get shopEmptyMessage => 'No items match this filter.';

  @override
  String get shopImportCsv => 'Import from CSV';

  @override
  String shopMarginPct(int pct) {
    return '$pct% margin';
  }

  @override
  String shopInStock(int count) {
    return '$count in stock';
  }

  @override
  String shopLeft(int count) {
    return '$count left';
  }

  @override
  String get editorNewItem => 'New item';

  @override
  String get editorEditItem => 'Edit item';

  @override
  String get editorName => 'Name';

  @override
  String get editorMaterialsPerItem => 'Materials per item (\$)';

  @override
  String get editorMinutesToMake => 'Minutes to make';

  @override
  String editorPriceSuggestion(String low, String high) {
    return 'Try $low to $high.';
  }

  @override
  String editorPriceSuggestionBreakEven(int units) {
    return ' Sell $units to cover your booth.';
  }

  @override
  String get editorPrice => 'Price (\$)';

  @override
  String get editorStartingStock => 'Starting stock';

  @override
  String get editorAddStock => 'Add stock';

  @override
  String get editorSave => 'Save';

  @override
  String get editorDeleteItem => 'Delete item';

  @override
  String get sellTitle => 'Your table, in a tap.';

  @override
  String get sellSearchHint => 'Search your items';

  @override
  String get sellBackToSingle => 'Back to single item';

  @override
  String get sellZoomToGrid => 'Zoom out to grid';

  @override
  String get sellAddItem => 'Add item';

  @override
  String sellRemoveOneSale(String name) {
    return 'Remove one $name sale';
  }

  @override
  String sellSellOne(String name) {
    return 'Sell one $name';
  }

  @override
  String get sellSoldOut => 'Sold out';

  @override
  String get sellOneSold => '+1 sold';

  @override
  String get sellMinus1 => '-1';

  @override
  String get sellNoItemsTitle => 'No items yet';

  @override
  String get sellNoItemsMessage => 'Add your first item with the + button.';

  @override
  String get sellNoMatchTitle => 'No match';

  @override
  String sellNoMatchMessage(String query) {
    return 'Nothing matches \"$query\"';
  }

  @override
  String sellPaidWith(String method) {
    return 'Paid with $method';
  }

  @override
  String sellGross(String amount) {
    return '$amount gross';
  }

  @override
  String sellPosition(int index, int total) {
    return '$index / $total';
  }

  @override
  String sellOpenItem(String name, int left, int sold) {
    return 'Open $name, $left left, $sold sold';
  }

  @override
  String sellSoldCount(int count) {
    return '$count sold';
  }

  @override
  String sellPriceSold(String price, int count) {
    return '$price / $count sold';
  }

  @override
  String get createTitle => 'Make a little noise.';

  @override
  String get createSearchHint => 'Search items to post';

  @override
  String get createPickItem => 'Pick an item';

  @override
  String createBackSoon(String name) {
    return '$name is back.';
  }

  @override
  String get createDefaultShopName => 'My shop';

  @override
  String get createCaptionLabel => 'CAPTION';

  @override
  String get createUseMine => 'Use mine';

  @override
  String get createAiVersion => 'AI version';

  @override
  String get createCaptionHint => 'Pick an item to start a caption';

  @override
  String get createShareOrSave => 'Share or save';

  @override
  String createShareShape(String noun) {
    return 'Share $noun';
  }

  @override
  String createSavedToPhotos(int width, int height) {
    return 'Saved $width x $height PNG to Photos';
  }

  @override
  String get createSaveFailed => 'Could not save. Allow Photos access in Settings.';

  @override
  String get createShapePost => 'Post';

  @override
  String get createShapeStory => 'Story';

  @override
  String get createShapeWide => 'Wide';

  @override
  String get createNounPost => 'post';

  @override
  String get createNounStory => 'story';

  @override
  String get createNounWide => 'wide post';

  @override
  String get createTargetPng => 'Save as PNG';

  @override
  String get createTargetInstagram => 'Instagram';

  @override
  String get createTargetFacebook => 'Facebook';

  @override
  String get createTargetLinkedin => 'LinkedIn';

  @override
  String get createTargetMore => 'More apps';

  @override
  String get createTargetMoreSubtitle => 'Messages, Shopify, Etsy and others';

  @override
  String createTargetPngSubtitle(int width, int height) {
    return '$width x $height to Photos';
  }

  @override
  String createTargetSizeSubtitle(int width, int height) {
    return '$width x $height';
  }

  @override
  String get insightsTitle => 'Look what you did.';

  @override
  String get insightsExport => 'Export';

  @override
  String get insightsExportPro => 'PRO';

  @override
  String get insightsPdfXlsxLocked => 'PDF and Excel exports are part of Pro.';

  @override
  String get insightsNetProfit => 'Net profit';

  @override
  String insightsNetCaption(String gross, String cost, String booth, int units) {
    return '$gross gross, $cost cost, $booth booth. $units sold.';
  }

  @override
  String get insightsProfitByItem => 'Profit by item';

  @override
  String get insightsHowTheyPaid => 'How they paid';

  @override
  String get insightsYourRecap => 'YOUR RECAP';

  @override
  String insightsReportTitle(String event) {
    return '$event report';
  }

  @override
  String get insightsAllSales => 'All sales';

  @override
  String get insightsThisEvent => 'this event';

  @override
  String insightsUnitsOverProfit(int units, String profit) {
    return '$units / $profit';
  }

  @override
  String insightsMethodAmount(String method, String amount) {
    return '$method $amount';
  }

  @override
  String get eventsTitle => 'Your events';

  @override
  String get eventsSettingsTooltip => 'Settings';

  @override
  String get eventsConsNearYou => 'Cons near you';

  @override
  String get eventsAdd => 'Add';

  @override
  String get eventsPrivacyNote =>
      'Distance is worked out on your phone. Your location is never sent anywhere.';

  @override
  String get eventsNew => 'New event';

  @override
  String get eventsImportIcs => 'Import .ics';

  @override
  String get eventsExport => 'Export';

  @override
  String get eventsNameDialogTitle => 'Event name';

  @override
  String get eventsSave => 'Save';

  @override
  String get eventsLive => 'LIVE';

  @override
  String get searchHintDefault => 'Search';

  @override
  String searchResultsFor(String query) {
    return 'Results for \"$query\"';
  }

  @override
  String get searchNothingFoundTitle => 'Nothing found';

  @override
  String get searchNothingFoundMessage => 'Try a shorter word.';

  @override
  String get searchItemsHeader => 'ITEMS';

  @override
  String get searchEventsHeader => 'EVENTS';

  @override
  String searchLeftPrice(int left, String price) {
    return '$left left  /  $price';
  }

  @override
  String get pupGreetingTitle => 'Hey, maker. I\'m PUP.';

  @override
  String get pupNeedHand => 'Need a hand?';

  @override
  String get pupCornerHint => 'I live in the corner. Tap me any time you get stuck.';

  @override
  String get pupLetsGo => 'Let\'s go';

  @override
  String get pupAskPup => 'Ask PUP';

  @override
  String get pupFaqOfflineQ => 'Does it work with no signal?';

  @override
  String get pupFaqOfflineA =>
      'Yes. Everything saves on your phone first. Pro backs it up when you are back online.';

  @override
  String get pupFaqDoubleTapQ => 'I tapped +1 twice by accident';

  @override
  String get pupFaqDoubleTapA =>
      'Tap -1 on the same item. It removes the last sale and puts the item back in stock.';

  @override
  String get pupFaqAddEventQ => 'How do I add an event?';

  @override
  String get pupFaqAddEventA =>
      'Tap the pass at the top of any screen, then New event, Import .ics, or pick a con near you.';

  @override
  String get pupFaqDataQ => 'Where is my data?';

  @override
  String get pupFaqDataA =>
      'On this phone only, unless you turn on Pro backup. We never sell your sales data.';

  @override
  String get pupFaqProQ => 'What does Pro add?';

  @override
  String get pupFaqProA =>
      'Cloud backup, AI captions and recaps, card reader sync, PDF and Excel exports.';

  @override
  String get connectionOffline => 'Offline, saved on phone';

  @override
  String get connectionSavedOnPhone => 'Saved on phone';

  @override
  String get connectionSynced => 'Synced';

  @override
  String connectionSyncing(int count) {
    return 'Syncing $count';
  }

  @override
  String get eventBarNoEvent => 'No event yet';

  @override
  String get eventBarAddOne => 'Add one';

  @override
  String eventBarLiveDay(int day) {
    return 'Live day $day';
  }

  @override
  String eventBarInDays(int days) {
    return 'In $days d';
  }

  @override
  String get eventBarEnded => 'Ended';

  @override
  String eventBarOpenEvents(String name) {
    return 'Open events. $name';
  }

  @override
  String get eventBarPass => 'PASS';

  @override
  String get eventBarNetToday => 'NET TODAY';

  @override
  String get paymentCash => 'Cash';

  @override
  String get paymentCard => 'Card';

  @override
  String get paymentZelle => 'Zelle';

  @override
  String get paymentVenmo => 'Venmo';

  @override
  String get paymentCashapp => 'Cash App';

  @override
  String get paymentPaypal => 'PayPal';

  @override
  String get paymentOther => 'Other';

  @override
  String get exportFormatCsv => 'CSV';

  @override
  String get exportFormatPng => 'PNG';

  @override
  String get exportFormatXlsx => 'Excel';

  @override
  String get exportFormatPdf => 'PDF report';

  @override
  String get aiPendingCaption => 'AI VERSION WRITING. KEEP WORKING.';

  @override
  String get asciiFreeModeNote =>
      'Free mode keeps your data on this phone. We never sell your sales data.';

  @override
  String get exportColSoldAt => 'Sold at';

  @override
  String get exportColItem => 'Item';

  @override
  String get exportColQty => 'Qty';

  @override
  String get exportColUnitPrice => 'Unit price';

  @override
  String get exportColUnitCost => 'Unit cost';

  @override
  String get exportColPaidWith => 'Paid with';

  @override
  String get exportColSource => 'Source';

  @override
  String get passHeaderLeft => 'POP UP PASS';

  @override
  String get passHeaderRight => 'NO. 1';

  @override
  String get passRole => 'MAKER';

  @override
  String get passAccess => 'ALL ACCESS';
}
