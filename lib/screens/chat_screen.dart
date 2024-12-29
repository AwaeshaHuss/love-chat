import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as FAuth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/message_input.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userImage;

  const ChatScreen({
    Key? key,
    required this.userId,
    required this.userName,
    required this.userImage,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? lastSeenMessageId;
  final FAuth.User? user = FAuth.FirebaseAuth.instance.currentUser;

  String _getChatId() {
    final users = [user!.uid, widget.userId];
    users.sort();
    return users.join('_');
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> _checkAndRequestPermissions() async {
    var status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
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

  @override
  Widget build(BuildContext context) {
    final maxBubbleWidth = MediaQuery.of(context).size.width * .7125;

    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        backgroundColor: Colors.green,
        leadingWidth: maxBubbleWidth * .085,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              backgroundImage: widget.userImage.isNotEmpty
                  ? NetworkImage(widget.userImage)
                  : const AssetImage('assets/images/logo.png')
                      as ImageProvider,
            ),
            const SizedBox(width: 10),
            Text(
              widget.userName,
              style: GoogleFonts.aBeeZee(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_getChatId())
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (ctx, chatSnapshot) {
                if (chatSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet',
                      style: GoogleFonts.aBeeZee(color: Colors.white70),
                    ),
                  );
                }

                final chatDocs = chatSnapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: chatDocs.length,
                  itemBuilder: (ctx, index) {
                    final message = chatDocs[index].data() as Map<String, dynamic>;
                    final isSender = message['senderId'] == user!.uid;
                    final timestamp = (message['createdAt'] as Timestamp).toDate();
                    final formattedDateTime = DateFormat('yyyy-MM-dd hh:mm').format(timestamp);


                    return Align(
                      alignment:
                          isSender ? Alignment.centerRight : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                        child: Container(
                          padding: (message['imageUrl'] != null &&
                                  message['imageUrl'].isNotEmpty) ? const EdgeInsets.all(4.0):const EdgeInsets.all(10.0),
                          margin: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSender
                                ? Colors.green[300]
                                : Colors.grey[700],
                            borderRadius: BorderRadius.only(
                              topRight: const Radius.circular(20.0),
                              topLeft: const Radius.circular(20.0),
                              bottomRight: isSender ? const Radius.circular(0):const Radius.circular(20.0),
                              bottomLeft: isSender ? const Radius.circular(20.0):const Radius.circular(0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isSender
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (message['imageUrl'] != null &&
                                  message['imageUrl'].isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16.0),
                                  child: FadeInImage.assetNetwork(
                                    image: message['imageUrl'],
                                    placeholder: 'assets/images/logo.png',
                                    width: maxBubbleWidth,
                                    height: 250,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              if (message['text'] != null &&
                                  message['text'].isNotEmpty)
                                Text(
                                  message['text'],
                                  style: GoogleFonts.aBeeZee(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              const SizedBox(height: 5),
                              Text(
                                formattedDateTime,
                                style: GoogleFonts.aBeeZee(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          MessageInput(
            currentUserId: user!.uid,
            recipientUserId: widget.userId,
          ),
        ],
      ),
    );
  }
}
