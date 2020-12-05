import 'dart:async';
import 'package:TicTacToe/model/mydialog.dart';
import 'package:TicTacToe/screens/users_screen.dart';
import 'package:flutter/material.dart';
import 'package:TicTacToe/screens/game_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:TicTacToe/model/utility.dart';
import 'package:http/http.dart' as http;


class HomeScreen extends StatefulWidget {
  HomeScreen({Key key, this.title}) : super(key: key);
  static const routeName = '/homeScreen';

  final String title;
  
  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        handleMessage(message);
      },
      onLaunch: (Map<String, dynamic> message) async {
        handleMessage(message);
      },
      onResume: (Map<String, dynamic> message) async {
        handleMessage(message);
      },
    );
    firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(sound: true, badge: true, alert: true));
    updateToken();
  }

  @override
  Widget build(BuildContext context) => Scaffold(      
      appBar:PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: AppBar(
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              widget.title,
              style: TextStyle(
                color: Colors.black,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          elevation: 0,
          flexibleSpace: ClipPath(
            clipper: _AppBarClipper(),
            child: Container(
                decoration: BoxDecoration(
              color: Colors.blue,
            )),
          ),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 50,),
            Image.asset('assets/images/tictactoe.jpg',width: 210,height: 150),
            SizedBox(height: 25,),
            Text("Choose Game Mode", style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold, color: Colors.red),),
            Card(
              elevation: 5.0,
              color: Colors.greenAccent,
                          child: MaterialButton(
                  onPressed: () {Navigator.of(context).pushNamed(GameScreen.routeName);},
                  child: Text('Single Player', style: TextStyle(fontSize: 20.0,color: Colors.blue))),
            ),
            Card(
              elevation: 5.0,
              color: Colors.greenAccent,
                          child: MaterialButton(
                  onPressed: () {inviteUsers();},
                  child: Text('Multi Player', style: TextStyle(fontSize: 25.0,color: Colors.blue))),
            ),
          ],
        ),
      ));

  void showInvitePopup(BuildContext context, Map<String, dynamic> message) {
   Timer(Duration(milliseconds: 200), () {
      showDialog<bool>(
        context: context,
        builder: (_) => buildDialog(context, message),
      );
    });
  }

  Widget buildDialog(BuildContext context, Map<String, dynamic> message) {
    var fromName = getValue(message, 'fromName');
    return AlertDialog(
      content: Text('$fromName invites you to play!'),
      actions: <Widget>[
        FlatButton(
          child: Text('Decline'),
          onPressed: () {Navigator.pop(context);},
        ),
        FlatButton(
          child: Text('Accept'),
          onPressed: () {accept(message);},
        ),
      ],
    );
  }

  // Inviting the users
  void inviteUsers() async {
    MyDialog.circularProgressStart(context);
    // Sign in with the google account first
    User user = await signInWithGoogle();
    // Save the user to the realtime database
    await saveUser(user);
    MyDialog.circularProgressEnd(context);
    // Start the multiplayer game then
    Navigator.of(context).pushNamed(UsersScreen.routeName,arguments: {'user':user});    
  }
   
  Future<User> signInWithGoogle() async {
    User user = await _auth.currentUser;
    if (user == null) {
      GoogleSignInAccount googleUser = _googleSignIn.currentUser;
      if (googleUser == null) {
        googleUser = await _googleSignIn.signInSilently();
        if (googleUser == null) {
          googleUser = await _googleSignIn.signIn();
        }
      }

      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      AuthCredential credential = GoogleAuthProvider.credential(idToken:googleAuth.idToken,accessToken:googleAuth.accessToken);
      UserCredential result = await _auth.signInWithCredential(credential);
      user = await _auth.currentUser;
      }
    return user;
  }

  Future<void> saveUser(User user) async {
    var token = await firebaseMessaging.getToken();
    await saveUserToPreferences(user.uid, user.displayName, user.email, token);

    var update = {
      'name': user.displayName,
      'email':user.email,
      'photoUrl': user.photoUrl,
      'pushId': token
    };
    return FirebaseDatabase.instance
        .reference()
        .child('users')       // heading under which users are  saved in realtime database
        .child(user.uid)
        .update(update);
  }

  saveUserToPreferences(String userId, String userName,String email, String pushId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('userId', userId);
    prefs.setString('email', email);
    prefs.setString('pushId', pushId);
    prefs.setString('userName', userName);
  }

  void updateToken() async {
    var currentUser = await _auth.currentUser;
    if (currentUser != null) {
      var token = await firebaseMessaging.getToken();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('pushId', token);

      FirebaseDatabase.instance
          .reference()
          .child('users')
          .child(currentUser.uid)
          .update({'pushId': token});
    }
  }

  void accept(Map<String, dynamic> message) async {
    Navigator.pop(context);
    String fromPushId = getValue(message, 'fromPushId');
    String fromId = getValue(message, 'fromId');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var username = prefs.getString('userName');
    var pushId = prefs.getString('pushId');
    var userId = prefs.getString('userId');

    var base = 'https://us-central1-rohan-map2020-tictactoe-c2242.cloudfunctions.net';
    String dataURL = '$base/Invitation?to=$fromPushId&fromPushId=$pushId&fromId=$userId&fromName=$username&type=accept';
    MyDialog.circularProgressStart(context);
    http.Response response = await http.get(dataURL);
    MyDialog.circularProgressEnd(context);
    String gameId = '$fromId-$userId';

    Navigator.of(context).push(new MaterialPageRoute(
        builder: (context) => new GameScreen(
            title: 'Multi Player',
            type: "Online",
            me: 'O',
            gameId: gameId,
            withId: fromId)));
  }

  void handleMessage(Map<String, dynamic> message) async {
    var type = getValue(message, 'type');
    var fromId = getValue(message, 'fromId');
    if (type == 'invite') {
      showInvitePopup(context, message);
    } else if (type == 'accept') {
      var currentUser = await _auth.currentUser;
      String gameId = '${currentUser.uid}-$fromId';
      Navigator.of(context).push(new MaterialPageRoute(
          builder: (context) => new GameScreen(
              title: 'Multi Player',
              type: "Online",
              me: 'X',
              gameId: gameId,
              withId: fromId)));
    } else if (type == 'reject') {}
  }
}


class _AppBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 50);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}