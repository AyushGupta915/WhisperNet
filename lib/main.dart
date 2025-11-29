import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:whispernet/screens/SettingsScreen.dart';
import 'package:whispernet/screens/chats.dart';
import 'package:whispernet/screens/login/verify_number.dart';
import 'package:whispernet/screens/people.dart';
import 'package:whispernet/screens/login/hello.dart';
import 'package:flutter/services.dart';

import 'screens/login/edit_number.dart';

//
// void main() {
//   runApp(const MyApp());
// }

const bool USE_EMULATOR = false;
bool loggedin = false;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //for transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // transparent status bar
    ),
  );

  await Firebase.initializeApp();

  if (USE_EMULATOR) {
    _connectToFirebaseEmulator();
  }

  //getting status of user in the initial stage of app
  await FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
      print('User is signed in!');
      loggedin = true;
    } else {
      print('User is currently signed out!');
      loggedin = false;
    }
  });

  // setting the active status of the user
  final storage = new FlutterSecureStorage();
  var userid = await storage.read(key: "number");
  FirebaseFirestore.instance.collection('user').doc(userid).update({
    'status': 'Online',
  });

  runApp(const MyApp());
}

Future _connectToFirebaseEmulator() async {
  final fireStorePort = "8080";
  final authPort = 9099;
  final storagePort = 9199;
  final localHost = Platform.isAndroid ? '10.0.2.2' : 'localhost';
  // String host = Platform.isAndroid ? '10.0.2.2:8080' : 'localhost:8080';

  FirebaseFirestore.instance.settings = Settings(
    host: "$localHost:$fireStorePort",
    // host: host,
    sslEnabled: false,
    persistenceEnabled: false,
  );

  await FirebaseAuth.instance.useAuthEmulator(localHost, authPort);
  await FirebaseStorage.instance.useStorageEmulator(localHost, storagePort);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return (loggedin == true)
        ? MaterialApp(
            home: HomePage(), //got to main home page
            theme: ThemeData(
              brightness: Brightness.light,
              primaryColor: Color(0xFF08C187),
            ),

            debugShowCheckedModeBanner: false,
          )
        : MaterialApp(
            home: Hello(), //start from hello page
            theme: ThemeData(
              brightness: Brightness.light,
              primaryColor: Color(0xFF08C187),
            ),

            debugShowCheckedModeBanner: false,
          );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  var screens = [Chats(), People(), SettingsScreen()];

  int _selectedIndex = 0;
  final storage = new FlutterSecureStorage();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  // setting the active status of the user
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    var userid = await storage.read(key: "number");
    if (state == AppLifecycleState.resumed) {
      print("The user is online");
      FirebaseFirestore.instance.collection('user').doc(userid).update({
        'status': 'Online',
      });
    }
    //TODO: set status to online here in firestore
    else {
      print("The user is offline");
      FirebaseFirestore.instance.collection('user').doc(userid).update({
        'status': 'Offline',
      });
    }
    //TODO: set status to offline here in firestore
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: screens[_selectedIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_rounded),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt),
              label: 'People',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.white, // selected = white
          unselectedItemColor: Colors.white70, // unselected = dim white
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
