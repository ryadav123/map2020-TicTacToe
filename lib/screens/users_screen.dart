import 'package:TicTacToe/model/myimageview.dart';
import 'package:TicTacToe/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:TicTacToe/model/gameUser.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class UsersScreen extends StatefulWidget {
  final String title;
  static const routeName = '/homeScreen/usersScreen';

  UsersScreen({Key key, this.title}) : super(key: key);

  @override
  UserListState createState() => UserListState();
}

class UserListState extends State<UsersScreen> {
  List<GameUser> _users = List<GameUser>();
  User user;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  @override
  void initState() {
    super.initState();
    getUsers();
  }

  @override
  Widget build(BuildContext context) {
    Map arg = ModalRoute.of(context).settings.arguments;
    user ??= arg['user'];
    return Scaffold(
        appBar:PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: AppBar(
          backgroundColor: Colors.white,
          title: Center(
            child: Column(
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(user.email,style: TextStyle(fontSize: 12),)
              ],
            ),
            
          ),
           actions: <Widget>[
            IconButton(
              icon: Icon(Icons.exit_to_app),
               onPressed: () { 
                 signOutWithGoogle();       
                },
               ),            
          ],
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
        body:         
          _users.length == 0
            ? Center(
              child: Text(
                  'No Registered Users',
                  style: TextStyle(fontSize: 30.0),
                ),
            )
           
            : ListView.builder(
                itemCount: _users.length,
                itemBuilder: (BuildContext context, int index) => Container(
                  padding: EdgeInsets.all(4),                  
                  child: Card(      
                      shape: RoundedRectangleBorder(borderRadius:BorderRadius.circular(20)),                               
                      color: Colors.yellow[200],
                      elevation: 20,
                      child: ListTile(
                      leading: Container(
                        height: 60,
                        width: 60,
                        child: MyImageView.network(
                            imageUrl: _users[index].photoUrl, context: context, ),
                      ),
                      trailing: Icon(Icons.keyboard_arrow_right),
                      title: _users[index].name == null ?
                      Center(child: Text('No Name',style: TextStyle(fontSize: 20, color: Colors.red),))
                      :Center(child: Text(_users[index].name,style: TextStyle(fontSize: 20, color: Colors.red),)),
                      subtitle: Center(child: Text(_users[index].email,style: TextStyle(fontSize: 15, color: Colors.red),)),
                      onTap: () {
                        Scaffold.of(context).showSnackBar(
                        SnackBar(content: Text('Invitation sent to ${_users[index].name}')));
                        invite(_users[index]);
                              },                      
                    ),
                  ),
                ),
              ),   
        );
  }
  Future <void> signOutWithGoogle()  async{
    await _auth.signOut();
    await _googleSignIn.signOut();
    Navigator.of(context).pushNamed(HomeScreen.routeName);
    
}
  void getUsers() async {
    var snapshot = await FirebaseDatabase.instance.reference().child('users').once();

    Map<String, dynamic> users = snapshot.value.cast<String, dynamic>();
    users.forEach((userId, userMap) {
      GameUser user = parseUser(userId, userMap);
      setState(() {
        _users.add(user);
      });
    });
  }

  GameUser parseUser(String userId, Map<dynamic, dynamic> user) {
    String name, photoUrl, pushId,email;
    user.forEach((key, value) {
      if (key == 'name') {name = value as String;}
      if (key == 'photoUrl') {photoUrl = value as String;}
      if (key == 'pushId') {pushId = value as String;}
      if (key == 'email') {email = value as String;}
                              });
    return GameUser(userId, name, photoUrl, pushId,email);
  }

  invite(GameUser user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var username = prefs.getString('userName');
    var pushId = prefs.getString('pushId');
    var userId = prefs.getString('userId');

    var base = 'https://us-central1-rohan-map2020-tictactoe-c2242.cloudfunctions.net';
    String dataURL = '$base/Invitation?to=${user.pushId}&fromPushId=$pushId&fromId=$userId&fromName=$username&type=invite';
    String gameId = '$userId-${user.id}';
    FirebaseDatabase.instance
        .reference()
        .child('games')
        .child(gameId)
        .set(null);
    http.Response response = await http.get(dataURL);
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