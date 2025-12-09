import 'package:altu_life/app/app.dart';
import 'package:altu_life/data/mock_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Application entry point.
///
/// Initializes the Flutter application with:
/// - Health and screen time data from JSON files
/// - Environment variables from .env file
/// - Riverpod's ProviderScope for state management
/// - System UI overlay styling
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load health and screen time data from JSON files
  await DataLoader.instance.loadData();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // .env file not found - continue without it
    debugPrint('Warning: .env file not found. Gemini chat will not work.');
  }

  // Set system UI overlay style for a polished look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Prefer portrait orientation for this health app
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: App()));
}
