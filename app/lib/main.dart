import 'app/core/material.dart';
import 'package:get_storage/get_storage.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init(); // local storage for the session token
  runApp(const CreditSeaApp());
}
