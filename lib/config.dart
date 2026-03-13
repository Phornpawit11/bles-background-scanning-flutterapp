import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environments {
  static const String PRODUCTION = 'prod';
  static const String QAS = 'QAS';
  static const String DEV = 'dev';
  static const String LOCAL = 'local';
}

class ConfigEnvironments {
  static String _currentEnvironments = Environments.LOCAL;

  static Future environments({required String env}) async {
    _currentEnvironments = env;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_environment', env);
  }

  static Future<void> loadSavedEnvironment() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEnv = prefs.getString('app_environment');
    if (savedEnv != null) {
      _currentEnvironments = savedEnv;
    }
  }

  static final List<EnvironmentsModel> _availableEnvironments = [
    EnvironmentsModel(
      env: Environments.LOCAL,
      url: dotenv.get('LOCAL_URL', fallback: 'http://192.168.68.109:8080'),
    ),
    EnvironmentsModel(
      env: Environments.DEV,
      url: dotenv.get('DEV_URL', fallback: 'https://tracksolidproapi.eyefleet.co/api'),
    ),
    EnvironmentsModel(
      env: Environments.QAS,
      url: dotenv.get('QAS_URL', fallback: 'https://tracksolidproapi.eyefleet.co/api'),
    ),
    EnvironmentsModel(
      env: Environments.PRODUCTION,
      url: dotenv.get('PROD_URL', fallback: 'https://tracksolidproapi.eyefleet.co/api'),
    ),
  ];

  static EnvironmentsModel getEnvironments() {
    return _availableEnvironments.firstWhere(
      (d) => d.env == _currentEnvironments,
    );
  }
}

class EnvironmentsModel {
  String? env;
  String? url;
  String? url2;
  String? url3;
  String? imageIur;
  EnvironmentsModel({this.env, this.url, this.url2, this.url3, this.imageIur});
}
