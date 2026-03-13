import 'package:bearcon_card_app/config.dart';
import 'package:bearcon_card_app/infrastructure/helper/app_initializer.helper.dart';
import 'package:bearcon_card_app/main.app.dart';
import 'package:flutter/material.dart';

import 'package:bearcon_card_app/infrastructure/navigation/routes.dart';

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app components
  await AppInitializer.initialize(env: Environments.PRODUCTION);
  var initialRoute = await Routes.initialRoute;

  runApp(Main(initialRoute: initialRoute));
}
