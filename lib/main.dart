import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:loginamc/views/bienvenidaView.dart';
import 'firebase_options.dart';
import 'package:loginamc/helpers/timezone_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  TimeZoneHelper.initializeTimeZones();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0XFF001220),
        ),
        home: const Bienvenidaview(),
      );
  }
}
