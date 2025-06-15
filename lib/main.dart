import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'login_page.dart';

Future<void> main() async {
  
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyCkdeDPxPQPhzAN3xt2xiiMgtXzlyt0AXE',
      appId: '1:81635281538:android:3fc4dab1f305fe34f1c29b',
      messagingSenderId: '81635281538',
      projectId: 'assignment2-e71f4',
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return const MaterialApp(
      home: LoginPage(),
    );
  }
}
