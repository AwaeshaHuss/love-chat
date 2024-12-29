import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as FAuth;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:love_chat/screens/auth_screen.dart';
import 'package:love_chat/screens/chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final FAuth.User? user = FAuth.FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.grey[850],
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: Colors.green,
          title: Text(
            'Contacts',
            style: GoogleFonts.aBeeZee(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 21,
            ),
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
        body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('uid', isNotEqualTo: user?.uid)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data?.docs.isEmpty == true) {
              return Center(
                child: Text(
                  'No contacts found.',
                  style: GoogleFonts.aBeeZee(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              );
            }

            final userDocs = snapshot.data!.docs;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: ListView.builder(
                itemCount: userDocs.length,
                itemBuilder: (ctx, index) {
                  final user = userDocs[index].data() as Map<String, dynamic>;
                  final displayName = user['displayName'] ?? 'Unknown';
                  final profileImage = user['profile-image'] ?? '';
                  final isTyping = user['isTyping'] ?? false;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 2.0, vertical: 6.0),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundImage: profileImage.isNotEmpty &&
                                Uri.tryParse(profileImage)?.isAbsolute == true
                            ? NetworkImage(profileImage)
                            : const AssetImage('assets/images/love.jpeg')
                                as ImageProvider,
                        radius: 24,
                      ),
                      title: Text(
                        displayName,
                        style: GoogleFonts.aBeeZee(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        isTyping ? 'typing...' : user['email'] ?? '',
                        style: GoogleFonts.aBeeZee(
                          color: isTyping ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_outlined),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ChatScreen(
                                    userId: user['uid'] ?? '',
                                    userName: displayName,
                                    userImage: profileImage),
                            ));
                        log('Tapped on user ${user['uid']}');
                        // Handle contact tap
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
