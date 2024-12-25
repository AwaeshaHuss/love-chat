import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as FAuth;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:love_chat/const.dart';
import 'package:love_chat/screens/auth_screen.dart';
import 'package:love_chat/screens/chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized in background handler
  await Firebase.initializeApp();
  log('A background message just showed up: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnon,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
  final FAuth.FirebaseAuth _auth = FAuth.FirebaseAuth.instance;
  final uid = _auth.currentUser?.uid;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Love Chat App',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
      home: uid == null ? const AuthScreen() : const ChatScreen(),
    );
  }
}
