import 'package:TicTacToe/screens/home_screen.dart';
import 'package:TicTacToe/screens/users_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:TicTacToe/screens/game_screen.dart';

void main() async{
    WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp();
   runApp(TicTacToe());
}
class TicTacToe extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
        title: 'Tic Tac Toe',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        
        home: HomeScreen(title: 'Home'),
        routes: <String, WidgetBuilder>{
          HomeScreen.routeName: (BuildContext context) => HomeScreen(title: 'Home',),
          GameScreen.routeName: (BuildContext context) => GameScreen(title: 'Player vs AI'),
          UsersScreen.routeName: (BuildContext context) => UsersScreen(title: 'Invite Users')
        },
      );
}
