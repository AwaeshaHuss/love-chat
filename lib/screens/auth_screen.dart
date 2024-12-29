import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as FAuth;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:love_chat/helpers/shared_prefs.dart';
import 'package:love_chat/screens/chat_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:love_chat/screens/contacts_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthType { signIn, signUp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController =
      TextEditingController(); // New controller for display name
  final FAuth.FirebaseAuth _auth = FAuth.FirebaseAuth.instance;
  final supabase = Supabase.instance.client;
  final ImagePicker picker = ImagePicker();
  File? imageFile;
  String? fileName;
  AuthType? authType;

  @override
  void initState() {
    super.initState();
    authType = AuthType.signUp;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose(); // Dispose name controller
    super.dispose();
  }

  Future<void> _pickAndUploadMedia(ImageSource source) async {
    final pickedFile = await (picker.pickImage(source: source));

    if (pickedFile == null) return;

    imageFile = File(pickedFile.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    const fileType = 'images';
    fileName = '$fileType/$timestamp-${imageFile?.path.split('/').last}';

    try {
      final response = await supabase.storage
          .from('love-chat')
          .upload(fileName!, imageFile ?? File(''));
      if (response.error == null) {
        log('${response.data}');
      } else {
        throw Exception('Upload failed: ${response.error!.message}');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading media: $error')),
        );
      }
    }
    setState(() {});
  }

  Future<void> _authenticate(bool isSignUp) async {
  setState(() {
    isLoading = true;
  });
  try {
    FAuth.UserCredential userCredential;
    String? uploadedImageUrl;

    if (isSignUp) {
      if (imageFile == null) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select profile image first')),
        );
        return;
      }

      // Upload the profile image to Supabase
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final fileName = 'images/$timestamp-${imageFile!.path.split('/').last}';

      try {
        final response =
            await supabase.storage.from('love-chat').upload(fileName, imageFile!);
        if (response.error == null) {
          uploadedImageUrl =
              supabase.storage.from('love-chat').getPublicUrl(fileName).data;
        } else {
          throw Exception('Image upload failed: ${response.error!.message}');
        }
      } catch (error) {
        setState(() {
          isLoading = false;
        });
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $error')),
        );
        }
        return;
      }

      // Create a new user in Firebase Auth
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'profile-image': uploadedImageUrl ?? '',
        'displayName': _nameController.text.trim(),
        'email': user.email,
        'uid': user.uid,
      },
      // SetOptions(merge: true),
      );
    }
    } else {
      // Sign in an existing user in Firebase Auth
      userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    }

    // await SharedPreferencesHelper.saveString('uploadedImageUrlKey', uploadedImageUrl ?? '');
    // await SharedPreferencesHelper.saveString('displayNameKey', _nameController.text.trim());

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ContactsScreen()),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
  setState(() {
    isLoading = false;
  });
}


  bool _securePassword = true;
  void _togglePasswordVisibility() {
    setState(() {
      _securePassword = !_securePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return authType == AuthType.signUp
        ? _buildBody(size)
        : _buildBody(size);
  }

  PopScope _buildBody(Size size) {
    return PopScope(
      canPop: false,
      child: Scaffold(
            backgroundColor: Colors.grey[850],
            body: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: size.height * 0.25,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12.0).copyWith(top: 32.0),
                      alignment: Alignment.topLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                         authType == AuthType.signUp
                         ? Container(
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    width: 2.75, color: Colors.lightGreen)),
                            child: CircleAvatar(
                              radius: 32,
                              child: imageFile == null
                                  ? IconButton(
                                      onPressed: () async {
                                        await _pickAndUploadMedia(
                                            ImageSource.gallery);
                                      },
                                      icon: Icon(
                                        Icons.image,
                                        color: Colors.grey[800],
                                        size: 28,
                                      ))
                                  : FittedBox(
                                      fit: BoxFit.cover,
                                      child: SizedBox(
                                          width: 66,
                                          height: 66,
                                          child: GestureDetector(
                                              onTap: () async {
                                                await _pickAndUploadMedia(
                                                    ImageSource.gallery);
                                              },
                                              child: ClipOval(child: Image.file(imageFile!))))),
                            ),
                          ):const SizedBox.shrink(),
                          
                          Text(
                            authType == AuthType.signIn
                            ?'Welcome Back!':'Welcome!',
                            style: GoogleFonts.aBeeZee(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                            ),
                          ),
                          Text(
                          authType == AuthType.signUp
                            ?'Sign Up':'SignIn',
                            style: GoogleFonts.aBeeZee(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 48.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        authType == AuthType.signUp
                        ?const SizedBox(height: 20):const SizedBox.shrink(),
                        authType == AuthType.signUp
                        ?TextField(
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.name,
                          controller: _nameController,
                          style: GoogleFonts.openSans(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon:
                                const Icon(Icons.person, color: Colors.green),
                            labelText: 'Name',
                            labelStyle:
                                GoogleFonts.openSans(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ):const SizedBox.shrink(),
                        const SizedBox(height: 20),
                        TextField(
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          controller: _emailController,
                          style: GoogleFonts.openSans(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon:
                                const Icon(Icons.email, color: Colors.green),
                            labelText: 'Email',
                            labelStyle:
                                GoogleFonts.openSans(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          keyboardType: TextInputType.visiblePassword,
                          controller: _passwordController,
                          style: GoogleFonts.aBeeZee(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon:
                                const Icon(Icons.lock, color: Colors.green),
                            labelText: 'Password',
                            labelStyle: GoogleFonts.aBeeZee(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              onPressed: _togglePasswordVisibility,
                              icon: Icon(
                                _securePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          obscureText: _securePassword,
                        ),
                        const SizedBox(height: 30),
                        isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 1,
                                  color: Colors.white,
                                ),
                              )
                            : ElevatedButton(
                                onPressed: () => authType == AuthType.signUp ?_authenticate(true):_authenticate(false),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Text(
                                  authType == AuthType.signUp
                        ?'Sign Up':'SignIn',
                                  style: GoogleFonts.aBeeZee(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12.0),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Expanded(child: Divider(thickness: 1.25)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                'Or',
                                style: GoogleFonts.aBeeZee(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(thickness: 1.25)),
                          ],
                        ),
                        Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(authType == AuthType.signUp
                        ?'don\'t have account,':'have account,',
                                style: GoogleFonts.aBeeZee(
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                ),
                              ),
                              InkWell(
                                onTap: () => 
                                authType == AuthType.signUp
                        ?setState(() {authType = AuthType.signIn;}): setState(() {authType = AuthType.signUp;}),
                                child: Text(
                                  authType == AuthType.signUp
                        ?' SignIn':'Sign Up',
                                  style: GoogleFonts.aBeeZee(
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
