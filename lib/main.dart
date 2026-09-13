import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'core/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Tek sefer, burada açılır: üstündeki her şey hazır bir depo bekler (§25).
  final storage = await StorageService.create();
  runApp(EmojiPuzzleApp(storage: storage));
}
