import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as FAuth;
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:love_chat/screens/auth_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:love_chat/widgets/message_input.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? lastSeenMessageId;
  final FAuth.User? user = FAuth.FirebaseAuth.instance.currentUser;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> _checkAndRequestPermissions() async {
    var status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _checkAndRequestPermissions();
    FirebaseMessaging.instance.subscribeToTopic('chat');
    FirebaseMessaging.instance.getToken().then((token) {
      log('FCM Token: $token');
    });
    setupNotificationListener();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> setupNotificationListener() async {
    FirebaseFirestore.instance
        .collection('chat')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();

        if (data['userId'] != user?.uid && doc.id != lastSeenMessageId) {
          lastSeenMessageId = doc.id;
          _showNotification(data['text'] ?? '', data['imageUrl'] ?? '');
        }
      }
    });
  }

  Future<void> _showNotification(String message, String? mediaUrl) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'new_message_channel',
      'New Messages',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      'New Message',
      mediaUrl?.isNotEmpty == true ? 'Media received!' : message,
      notificationDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.green,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.lightGreenAccent,
                  width: 2.5,
                )
              ),
              child: CircleAvatar(
                child: ClipOval(child: Image.asset('assets/images/love.jpeg')),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Love',
              style: GoogleFonts.aBeeZee(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () {
              FAuth.FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('chat')
                  .orderBy('createdAt', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (ctx, AsyncSnapshot<QuerySnapshot> chatSnapshot) {
                if (chatSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final chatDocs = chatSnapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: chatDocs.length,
                  itemBuilder: (ctx, index) {
                    final data = chatDocs[index].data() as Map<String, dynamic>;
                    final isMe = data['userId'] == user?.uid;
                    final message = data['text'] as String?;
                    final imageUrl = data['imageUrl'] as String?;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        padding: imageUrl != null && imageUrl.isNotEmpty
                            ? const EdgeInsets.all(4)
                            : const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * .7,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green[300] : Colors.white,
                          borderRadius: BorderRadius.only(
                            topRight: const Radius.circular(12.0),
                            topLeft: const Radius.circular(12.0),
                            bottomLeft: isMe
                                ? const Radius.circular(18.0)
                                : Radius.zero,
                            bottomRight: isMe
                                ? Radius.zero
                                : const Radius.circular(18.0),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 3,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: FadeInImage(
                                  image: NetworkImage(imageUrl),
                                  placeholder: const AssetImage('assets/images/logo.png'),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 250,
                                ),
                              )
                            : Text(
                                message ?? '',
                                style: GoogleFonts.aBeeZee(
                                  color: isMe ? Colors.black : Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          const MessageInput(),
        ],
      ),
    );
  }
}
