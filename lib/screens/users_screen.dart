import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:TicTacToe/common/constants.dart';
import 'package:TicTacToe/model/gameUser.dart';
//import 'package:TicTacToe/user_list/user_list.dart';
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
    fetchUsers();
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
      child: InkWell(
          onTap: () {
            Scaffold.of(context).showSnackBar(
                SnackBar(content: Text('Clicked on ${_users[index].name}')));
            invite(_users[index]);
          },
          child: Container(
              padding: EdgeInsets.all(16.0),
              alignment: Alignment.centerLeft,
              child: Text(
                '${_users[index].name}',
                // Some weird bugs if passed without quotes
                style: TextStyle(fontSize: 18.0),
              ))));

  void fetchUsers() async {
    var snapshot =
        await FirebaseDatabase.instance.reference().child(USERS).once();

    Map<String, dynamic> users = snapshot.value.cast<String, dynamic>();
    users.forEach((userId, userMap) {
      GameUser user = parseUser(userId, userMap);
      setState(() {
        _users.add(user);
      });
    });
  }

  // Haven't figured out how to use built-in map-to-POJO parsers yet
  GameUser parseUser(String userId, Map<dynamic, dynamic> user) {
    String name, photoUrl, pushId;
    user.forEach((key, value) {
      if (key == NAME) {
        name = value as String;
      }
      if (key == PHOTO_URL) {
        photoUrl = value as String;
      }
      if (key == PUSH_ID) {
        pushId = value as String;
      }
    });

    return GameUser(userId, name, photoUrl, pushId);
  }

  invite(GameUser user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var username = prefs.getString(USER_NAME);
    var pushId = prefs.getString(PUSH_ID);
    var userId = prefs.getString(USER_ID);

    //var base = 'https://us-central1-tictactoe-64902.cloudfunctions.net';
    var base = 'https://us-central1-rohan-map2020-tictactoe-c2242.cloudfunctions.net';
    String dataURL = '$base/sendNotification?to=${user
        .pushId}&fromPushId=$pushId&fromId=$userId&fromName=$username&type=invite';
    print(dataURL);
    print('\n\n\n\n');
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