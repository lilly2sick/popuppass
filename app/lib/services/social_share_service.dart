import 'dart:io';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Where a post is going when it leaves the app.
enum SocialApp { instagram, facebook }

/// How a share was delivered.
enum ShareRoute { directToApp, systemSheet }

/// Instagram and Facebook sharing for Create.
///
/// With a Meta app id configured (`META_APP_ID` in config.dart) the image is
/// handed straight to the app's Stories composer over the native channel
/// (Android intents `com.instagram.share.ADD_TO_STORY` and
/// `com.facebook.stories.ADD_TO_STORY`; iOS `instagram-stories://` and
/// `facebook-stories://` with the pasteboard). Without an id, or when the
/// app is not installed, the system share sheet opens with the exact-size
/// PNG and the caption.
class SocialShareService {
  SocialShareService({
    required this.metaAppId,
    MethodChannel? channel,
    Future<void> Function(File image, String caption)? systemShare,
  }) : _channel = channel ?? const MethodChannel(channelName),
       _systemShare = systemShare ?? _shareSheet;

  static const channelName = 'com.popuppass/social';

  final String metaAppId;
  final MethodChannel _channel;
  final Future<void> Function(File image, String caption) _systemShare;

  bool get hasMetaApp => metaAppId.isNotEmpty;

  static Future<void> _shareSheet(File image, String caption) =>
      Share.shareXFiles([XFile(image.path, mimeType: 'image/png')], text: caption);

  Future<ShareRoute> share(SocialApp app, File image, String caption) async {
    if (hasMetaApp && await _tryDirect(app, image)) return ShareRoute.directToApp;
    await _systemShare(image, caption);
    return ShareRoute.systemSheet;
  }

  Future<bool> _tryDirect(SocialApp app, File image) async {
    try {
      return await _channel.invokeMethod<bool>('shareToStory', {
            'app': app.name,
            'path': image.path,
            'appId': metaAppId,
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
