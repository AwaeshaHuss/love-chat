// import 'package:agora_uikit/agora_uikit.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:love_chat/const.dart';

// class VideoCallScreen extends StatefulWidget {
//   const VideoCallScreen({super.key});

//   @override
//   State<VideoCallScreen> createState() => _VideoCallScreenState();
// }

// class _VideoCallScreenState extends State<VideoCallScreen> {
//   AgoraClient? client;

//   void initAgora() async {
//     final User? user = FirebaseAuth.instance.currentUser;
//     client = AgoraClient(
//         agoraConnectionData: AgoraConnectionData(
//             appId: agoraAppId, channelName: agoraChannelName, username: user?.displayName));
//             await client!.initialize();
//             setState(() {});
//   }

//   @override
//   void initState() {
//     super.initState();
//     initAgora();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(child: Stack(
//         children: [
//           AgoraVideoViewer(client: client!, layoutType: Layout.oneToOne, enableHostControls: true,),
//           AgoraVideoButtons(client: client!, addScreenSharing: false,)
//         ],
//       )),
//     );
//   }
// }
