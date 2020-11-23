import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:TicTacToe/common/constants.dart';
import 'package:TicTacToe/model/gameuser.dart';
import 'package:TicTacToe/user_list/user_list.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserListState extends State<UserList> {
  List<gameUser> _users = List<gameUser>();

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    print('build');

    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
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
      gameUser user = parseUser(userId, userMap);
      setState(() {
        _users.add(user);
      });
    });
  }

  // Haven't figured out how to use built-in map-to-POJO parsers yet
  gameUser parseUser(String userId, Map<dynamic, dynamic> user) {
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

    return gameUser(userId, name, photoUrl, pushId);
  }

  invite(gameUser user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var username = prefs.getString(USER_NAME);
    var pushId = prefs.getString(PUSH_ID);
    var userId = prefs.getString(USER_ID);

    var base = 'https://us-central1-tictactoe-64902.cloudfunctions.net';
    String dataURL = '$base/sendNotification2?to=${user
        .pushId}&fromPushId=$pushId&fromId=$userId&fromName=$username&type=invite';
    print(dataURL);
    String gameId = '$userId-${user.id}';
    FirebaseDatabase.instance
        .reference()
        .child('games')
        .child(gameId)
        .set(null);
    http.Response response = await http.get(dataURL);
  }
}
