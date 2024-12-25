import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as FAuth;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageInput extends StatefulWidget {
  const MessageInput({Key? key}) : super(key: key);

  @override
  _MessageInputState createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final supabase = Supabase.instance.client;
  final ImagePicker picker = ImagePicker();

  Future<void> _pickAndUploadMedia(ImageSource source, {bool isVideo = false}) async {
    Navigator.pop(context); // Close the bottom sheet after option selection.
    final pickedFile = await (isVideo 
        ? picker.pickVideo(source: source)
        : picker.pickImage(source: source));
        
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final fileType = isVideo ? 'videos' : 'images';
    final fileName = '$fileType/$timestamp-${file.path.split('/').last}';

    try {
      final response = await supabase.storage.from('love-chat').upload(fileName, file);
      if (response.error == null) {
        final mediaUrl = supabase.storage.from('love-chat').getPublicUrl(fileName).data!;
        _sendMessage(mediaUrl: mediaUrl, isVideo: isVideo);
      } else {
        throw Exception('Upload failed: ${response.error!.message}');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading media: $error')),
      );
    }
  }

  void _sendMessage({String? mediaUrl, bool isVideo = false}) {
    final user = FAuth.FirebaseAuth.instance.currentUser;
    if (user == null || (mediaUrl == null && _controller.text.trim().isEmpty)) {
      return;
    }

    FirebaseFirestore.instance.collection('chat').add({
      'text': mediaUrl == null ? _controller.text.trim() : '',
      'createdAt': Timestamp.now(),
      'userId': user.uid,
      'imageUrl': isVideo ? '' : mediaUrl ?? '',
      'videoUrl': isVideo ? mediaUrl ?? '' : '',
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.camera),
                      title: const Text('Capture Image'),
                      onTap: () => _pickAndUploadMedia(ImageSource.camera),
                    ),
                    ListTile(
                      leading: const Icon(Icons.image),
                      title: const Text('Select Image'),
                      onTap: () => _pickAndUploadMedia(ImageSource.gallery),
                    ),
                  ],
                ),
              );
            },
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: () => _sendMessage(),
          ),
          labelText: 'Send a message...',
          labelStyle: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}