import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:TicTacToe/common/constants.dart';
import 'package:TicTacToe/game/game.dart';
import 'package:TicTacToe/launcher/launcher.dart';
import 'package:TicTacToe/user_list/user_list.dart';

void main() async{
    WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp();
   runApp(TicTacToe());
}
class TicTacToe extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Tic Tac Toe',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Launcher(title: 'Tic Tac Toe'),
        routes: <String, WidgetBuilder>{
          SINGLE_GAME: (BuildContext context) => Game(title: 'Tic Tac Toe'),
          USER_LIST: (BuildContext context) => UserList(title: 'All users')
        },
      );
}
