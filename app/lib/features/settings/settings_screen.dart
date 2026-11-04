import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/components/grid_background.dart';
import '../../design/components/sticker.dart';
import '../../design/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../services/haptics_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _goPro() async {
    final auth = ref.read(authProvider);
    final purchases = ref.read(purchasesProvider);
    if (auth != null && auth.user == null) {
      final user = await auth.signInWithPlatform();
      if (user == null) return;
      await purchases.identify(user.id);
    }
    await purchases.purchasePro();
    await ref.read(syncServiceProvider)?.backfill();
  }

  Future<void> _restore() async {
    final auth = ref.read(authProvider);
    if (auth != null) {
      final user = auth.user ?? await auth.signInWithPlatform();
      if (user == null) return;
      await ref.read(purchasesProvider).identify(user.id);
      await ref.read(syncServiceProvider)?.restore();
    }
    await ref.read(purchasesProvider).restore();
  }

  @override
  Widget build(BuildContext context) {
    final haptics = ref.watch(hapticsProvider);
    final pro = ref.watch(entitlementsProvider).isPro;
    final auth = ref.watch(authProvider);
    final payments = ref.watch(paymentProviderProvider);
    final l10n = AppLocalizations.of(context);

    return GridBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(l10n.settingsTitle, style: PPType.heading()),
          backgroundColor: Colors.transparent,
        ),
        body: ListView(
          padding: const EdgeInsets.all(PPSpace.gutter),
          children: [
            StickerCard(
              fill: pro ? PPColors.violetSoft : PPColors.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(pro ? l10n.settingsPro : l10n.settingsFreePass, style: PPType.heading()),
                  const SizedBox(height: PPSpace.xs),
                  Text(
                    pro ? l10n.settingsProBody : l10n.settingsFreeBody,
                    style: PPType.body(size: 14, color: PPColors.muted),
                  ),
                  const SizedBox(height: PPSpace.md),
                  if (!pro) PPButton(label: l10n.settingsGoPro, onPressed: _goPro, expand: true),
                  const SizedBox(height: PPSpace.sm),
                  PPButton.secondary(
                    label: l10n.settingsRestore,
                    onPressed: _restore,
                    expand: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: PPSpace.lg),
            SwitchListTile(
              title: Text(l10n.settingsHaptics),
              value: haptics.enabled,
              onChanged: (v) => setState(() => haptics.enabled = v),
            ),
            ListTile(
              title: Text(l10n.settingsHapticStrength),
              subtitle: Slider(
                value: haptics.intensity,
                onChanged: haptics.enabled ? (v) => setState(() => haptics.intensity = v) : null,
                onChangeEnd: (_) => haptics.play(HapticMoment.sold),
              ),
            ),
            ListTile(
              title: Text(l10n.settingsCardReader(payments.displayName)),
              trailing: FutureBuilder(
                future: payments.isConnected,
                builder: (_, s) => TextButton(
                  onPressed: () async {
                    s.data == true ? await payments.disconnect() : await payments.connect();
                    setState(() {});
                  },
                  child: Text(s.data == true ? l10n.settingsDisconnect : l10n.settingsConnect),
                ),
              ),
            ),
            if (auth?.user != null) ...[
              const Divider(),
              ListTile(title: Text(l10n.settingsSignOut), onTap: () => auth!.signOut()),
              ListTile(
                title: Text(
                  l10n.settingsDeleteAccount,
                  style: PPType.body(color: PPColors.pink, weight: FontWeight.w700),
                ),
                subtitle: Text(l10n.settingsDeleteSubtitle),
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(l10n.settingsDeleteConfirmTitle),
                      content: Text(l10n.settingsDeleteConfirmBody),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) await auth!.deleteAccount();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
