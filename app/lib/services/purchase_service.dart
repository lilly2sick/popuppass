import 'dart:async';
import 'dart:io';

import 'package:purchases_flutter/purchases_flutter.dart';

import 'entitlements.dart';

/// RevenueCat over App Store and Play billing. Entitlement id: `pro`.
abstract interface class PurchaseService {
  Stream<Entitlements> get entitlements;
  Future<void> init();

  /// Ties the subscription to our account so it follows the user across devices.
  Future<void> identify(String userId);
  Future<void> purchasePro();
  Future<void> restore();
}

class RevenueCatPurchases implements PurchaseService {
  RevenueCatPurchases({required this.appleKey, required this.googleKey});

  final String appleKey;
  final String googleKey;
  final _ctrl = StreamController<Entitlements>.broadcast();

  static const entitlementId = 'pro';

  @override
  Stream<Entitlements> get entitlements => _ctrl.stream;

  @override
  Future<void> init() async {
    await Purchases.configure(PurchasesConfiguration(Platform.isIOS ? appleKey : googleKey));
    Purchases.addCustomerInfoUpdateListener(_emit);
    _emit(await Purchases.getCustomerInfo());
  }

  void _emit(CustomerInfo info) =>
      _ctrl.add(Entitlements(isPro: info.entitlements.active.containsKey(entitlementId)));

  @override
  Future<void> identify(String userId) async => _emit((await Purchases.logIn(userId)).customerInfo);

  @override
  Future<void> purchasePro() async {
    final offerings = await Purchases.getOfferings();
    final pkg = offerings.current?.monthly;
    if (pkg == null) throw StateError('No Pro offering configured in RevenueCat');
    _emit(await Purchases.purchasePackage(pkg));
  }

  @override
  Future<void> restore() async => _emit(await Purchases.restorePurchases());
}

/// Offline dev: flip Pro on and off from Settings.
class FakePurchases implements PurchaseService {
  final _ctrl = StreamController<Entitlements>.broadcast();
  bool _pro = false;

  @override
  Stream<Entitlements> get entitlements => _ctrl.stream;

  @override
  Future<void> init() async => _ctrl.add(Entitlements(isPro: _pro));

  @override
  Future<void> identify(String userId) async {}

  @override
  Future<void> purchasePro() async => _ctrl.add(Entitlements(isPro: _pro = true));

  @override
  Future<void> restore() async => _ctrl.add(Entitlements(isPro: _pro));

  void setPro(bool v) => _ctrl.add(Entitlements(isPro: _pro = v));
}
