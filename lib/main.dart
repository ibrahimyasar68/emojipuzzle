import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'core/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Opened once, here: everything above it wants a store that is already
  // there (§25).
  final storage = await StorageService.create();
  runApp(EmojiPuzzleApp(storage: storage));
}
