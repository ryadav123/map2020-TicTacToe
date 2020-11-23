import 'package:flutter/material.dart';
import 'package:TicTacToe/user_list/user_list_state.dart';

class UserList extends StatefulWidget {
  final String title;

  UserList({Key key, this.title}) : super(key: key);

  @override
  UserListState createState() => UserListState();
}
