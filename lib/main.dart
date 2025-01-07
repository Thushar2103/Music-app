// import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:music_app/services/config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home.dart';

void main() async {
  await Supabase.initialize(
    url: Config.supabaseUrl,
    anonKey: Config.supabaseAnon,
  );
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    doWhenWindowReady(() {
      final win = appWindow;
      win.minSize = Size(200, 200);
      win.size = Size(400, 600);
      win.alignment = Alignment.centerRight;
      win.show();
    });
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeData darkTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Color(0xFF1E1E1E),
      primaryColor: Colors.blueAccent,
      textTheme: TextTheme(),
      sliderTheme: SliderThemeData(
        activeTrackColor: Colors.white,
        trackHeight: 4.0,
        thumbColor: Colors.white,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 16.0),
        valueIndicatorColor: Colors.white,
        valueIndicatorTextStyle: TextStyle(color: Colors.black),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Color(0xFF462F56)),
              foregroundColor: WidgetStatePropertyAll(Colors.black),
              textStyle: WidgetStatePropertyAll(
                  TextStyle(fontWeight: FontWeight.bold)),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))))),
      fontFamily: 'lexend');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MusiHolic',
      // theme: theme,
      debugShowCheckedModeBanner: false,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
      home: MusicFileViewer(),
    );
  }
}
