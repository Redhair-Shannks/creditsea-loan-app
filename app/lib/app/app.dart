import 'core/material.dart';
import 'package:get/get.dart';

import 'core/bindings/initial_binding.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

class CreditSeaApp extends StatelessWidget {
  const CreditSeaApp({super.key});

  @override
  Widget build(BuildContext context) => GetMaterialApp(
        title: 'CreditSea',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialBinding: InitialBinding(),
        initialRoute: Routes.splash,
        getPages: AppPages.pages,
        defaultTransition: Transition.cupertino,
      );
}
