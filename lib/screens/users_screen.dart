import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:TicTacToe/model/gameUser.dart';
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

  @override
  void initState() {
    super.initState();
    getUsers();
  }

  @override
  Widget build(BuildContext context) {
    print('build');

    return Scaffold(
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
           actions: <Widget>[
            IconButton(
              icon: Icon(Icons.home),
               onPressed: () {                  
                
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
        body: ListView.builder(
            itemCount: _users.length, itemBuilder: buildListRow));
  }

  Widget buildListRow(BuildContext context, int index) => Container(
      height: 56.0,
      child: Card(            
            color: Colors.green[100],
            elevation: 5,
            child: InkWell(
            onTap: () {
              Scaffold.of(context).showSnackBar(
                  SnackBar(content: Text('Invitation sent to ${_users[index].name}')));
              invite(_users[index]);
            },
            child: Container(
                padding: EdgeInsets.all(8.0),
                alignment: Alignment.centerLeft,
                child: Center(
                  child: Text(
                    '${_users[index].name}',
                    style: TextStyle(fontSize: 20.0),
                  ),
                ))),
      ));

  void getUsers() async {
    var snapshot =
        await FirebaseDatabase.instance.reference().child('users').once();

    Map<String, dynamic> users = snapshot.value.cast<String, dynamic>();
    users.forEach((userId, userMap) {
      GameUser user = parseUser(userId, userMap);
      setState(() {
        _users.add(user);
      });
    });
  }

  GameUser parseUser(String userId, Map<dynamic, dynamic> user) {
    String name, photoUrl, pushId;
    user.forEach((key, value) {
      if (key == 'name') {
        name = value as String;
      }
      if (key == 'photoUrl') {
        photoUrl = value as String;
      }
      if (key == 'pushId') {
        pushId = value as String;
      }
    });

    return GameUser(userId, name, photoUrl, pushId);
  }

  invite(GameUser user) async {
    print('Inviting user...\n');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var username = prefs.getString('userName');
    var pushId = prefs.getString('pushId');
    var userId = prefs.getString('userId');

    var base = 'https://us-central1-rohan-map2020-tictactoe-c2242.cloudfunctions.net';
    String dataURL = '$base/Invitation?to=${user
        .pushId}&fromPushId=$pushId&fromId=$userId&fromName=$username&type=invite';
    String gameId = '$userId-${user.id}';
    FirebaseDatabase.instance
        .reference()
        .child('games')
        .child(gameId)
        .set(null);
    print('Invitation sent waiting for reply...\n');
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