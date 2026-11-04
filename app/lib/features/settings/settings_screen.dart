import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/components/sticker.dart';
import '../../design/tokens.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: PPType.heading()),
        backgroundColor: PPColors.bg,
      ),
      body: ListView(
        padding: const EdgeInsets.all(PPSpace.gutter),
        children: [
          StickerCard(
            fill: pro ? PPColors.violetSoft : PPColors.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(pro ? 'You are on Pro' : 'Free pass', style: PPType.heading()),
                const SizedBox(height: PPSpace.xs),
                Text(
                  pro
                      ? 'Cloud backup, AI captions and summaries, PDF and Excel exports.'
                      : 'Everything stays on this phone. Pro adds cloud backup, AI captions, and PDF and Excel exports.',
                  style: PPType.body(size: 14, color: PPColors.muted),
                ),
                const SizedBox(height: PPSpace.md),
                if (!pro) PPButton(label: 'Go Pro', onPressed: _goPro, expand: true),
                const SizedBox(height: PPSpace.sm),
                PPButton.secondary(label: 'Restore purchases', onPressed: _restore, expand: true),
              ],
            ),
          ),
          const SizedBox(height: PPSpace.lg),
          SwitchListTile(
            title: const Text('Haptics'),
            value: haptics.enabled,
            onChanged: (v) => setState(() => haptics.enabled = v),
          ),
          ListTile(
            title: const Text('Haptic strength'),
            subtitle: Slider(
              value: haptics.intensity,
              onChanged: haptics.enabled ? (v) => setState(() => haptics.intensity = v) : null,
              onChangeEnd: (_) => haptics.play(HapticMoment.sold),
            ),
          ),
          ListTile(
            title: Text('Card reader: ${payments.displayName}'),
            trailing: FutureBuilder(
              future: payments.isConnected,
              builder: (_, s) => TextButton(
                onPressed: () async {
                  s.data == true ? await payments.disconnect() : await payments.connect();
                  setState(() {});
                },
                child: Text(s.data == true ? 'Disconnect' : 'Connect'),
              ),
            ),
          ),
          if (auth?.user != null) ...[
            const Divider(),
            ListTile(title: const Text('Sign out'), onTap: () => auth!.signOut()),
            ListTile(
              title: Text(
                'Delete account',
                style: PPType.body(color: PPColors.pink, weight: FontWeight.w700),
              ),
              subtitle: const Text('Deletes your cloud backup. Data on this phone stays.'),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete account?'),
                    content: const Text('Your cloud backup is removed for good.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
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
    );
  }
}
