import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Bootstrap runs inside the app so the lanyard loader shows while it works.
  runApp(ProviderScope(child: PopUpPassApp(config: AppConfig.fromEnvironment())));
}
