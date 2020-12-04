import 'dart:async';
import 'package:TicTacToe/model/winnerline.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:TicTacToe/model/ai.dart';

class GameScreen extends StatefulWidget {

  static const routeName = '/homeScreen/gameScreen';

  GameScreen({Key key, this.title, this.type, this.me, this.gameId, this.withId})
      : super(key: key);

  final String title, type, me, gameId, withId;

  @override
  GameState createState() => GameState(type: type, me: me, gameId: gameId, withId: withId);
}

class GameState extends State<GameScreen> {
  BuildContext _context;
  List<List<String>> field = [
    ['', '', ''],
    ['', '', ''],
    ['', '', '']
  ];
  AI ai;
  String playerChar = 'X', aiChar = 'O';
  bool playersTurn = true;
 
  final String type, me, gameId, withId;
  bool winner = false;
  bool draft = false;
  int winrow = -1;
  int wincol = -1;
  String winline = "";
  
  GameState({this.type, this.me, this.gameId, this.withId});

  @override
  void initState() {
    super.initState();
    if (me != null) {
      playersTurn = me == 'X';
      playerChar = me;

      FirebaseDatabase.instance
          .reference()
          .child('games')
          .child(gameId)
          .onChildAdded
          .listen((Event event) {
        String key = event.snapshot.key;
        if (key != 'restart') {
          int row = int.parse(key.substring(0, 1));
          int column = int.parse(key.substring(2, 3));
          if (field[row][column] != me) {
            setState(() {
              field[row][column] = event.snapshot.value;
              playersTurn = true;
              Timer(Duration(milliseconds: 600), () {
                setState(() {
                  winnerCheck();
                });
              });
            });
          }
        } else if (key == 'restart') {
          FirebaseDatabase.instance.reference().child(gameId).set(null);

          setState(() {
            Scaffold.of(_context).hideCurrentSnackBar();
            cleanUp();
          });
        }
      });
      new Timer(Duration(milliseconds: 1000), () {
        String text = playersTurn ? 'Your turn' : 'Opponent\'s turn';
        Scaffold.of(_context).showSnackBar(SnackBar(content: Text(text)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ai = AI(field, playerChar, aiChar);
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
              icon: Icon(Icons.forward_5),
               onPressed: () {                  
                  if (type == null) {
                    setState(() {
                      winner = false; 
                      draft = false;                    
                      field = [
                        ['', '', ''],
                        ['', '', ''],
                        ['', '', '']
                      ];
                      playersTurn = true;
                    });
                  } else {
                    restart();
                  }
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
  body: Builder(builder: (BuildContext context) {
          _context = context;
          return Center(
              child: Stack(                  
                  children: [
                    // Building the Grid
                    AspectRatio(
                                aspectRatio: 1.0,
                                child: Stack(
                                  children: [
                                    Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                                      buildHorizontalLine,
                                      buildHorizontalLine,
                                    ]),
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                                      buildVerticalLine,
                                      buildVerticalLine,
                                    ])
                                  ],
                                )),
                    // Building the Field like each box
                    AspectRatio(
                                  aspectRatio: 1.0,
                                  child:
                                      Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                                    Expanded(
                                        child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                          buildCell(0, 0),
                                          buildCell(0, 1),
                                          buildCell(0, 2),
                                        ])),
                                    Expanded(
                                        child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                          buildCell(1, 0),
                                          buildCell(1, 1),
                                          buildCell(1, 2),
                                        ])),
                                    Expanded(
                                        child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                          buildCell(2, 0),
                                          buildCell(2, 1),
                                          buildCell(2, 2),
                                        ]))
                                  ])),
                    // Building thw winner line if any
                    AspectRatio(
                           aspectRatio: 1.0, child: CustomPaint(painter: WinnerLine(winner,winline,winrow,wincol)))
                    ]));
        }));
  }

  Container get buildVerticalLine => Container(
      margin: EdgeInsets.only(top: 16.0, bottom: 16.0),
      color: Colors.black,
      width: 10.0);

  Container get buildHorizontalLine => Container(
      margin: EdgeInsets.only(left: 16.0, right: 16.0),
      color: Colors.black,
      height: 10.0);

  Widget buildCell(int row, int column) => AspectRatio(
      aspectRatio: 1.0,
      child: GestureDetector(
          onTap: () {
            // Displaying player turn
            if (!gameIsDone() && playersTurn && !cellTaken(row, column)) {
              setState(() {
                  playersTurn = false;
                  field[row][column] = playerChar;
                  // In case of multiplayer
                      if (type != null && type == 'Online') {
                        FirebaseDatabase.instance
                            .reference()
                            .child('games')
                            .child(gameId)
                            .child('${row}_${column}')
                            .set(me);
                      }

                  Timer(Duration(milliseconds: 100), () {                   
                      winnerCheck();                  
                  });                
              });

              // Displaying AI turn       
             if (!gameIsDone() && type == null) {    

                  print('Inside ai if');   
                  print("Winner = $winner");       
                  Timer(Duration(milliseconds: 1000), () {
                    setState(() {
                    // AI turn
                    var aiDecision = ai.getDecision();
                    field[aiDecision.row][aiDecision.column] = aiChar;
                    playersTurn = true;
                    Timer(Duration(milliseconds: 600), () {
                        winnerCheck();
                    });
                  });
                });    
              }
            }            
          }, 
          child: buildCellItem(row, column)));

  Widget buildCellItem(int row, int column) {
    var cell = field[row][column];
    if (cell.isNotEmpty) {
      if (cell == 'X') {
        return Container(padding: EdgeInsets.all(14.0), child: 
        Text('X',style: TextStyle(fontSize: 100,fontWeight: FontWeight.bold,color: Colors.red,),textAlign: TextAlign.center,));
        
      } else {
        return Container(padding: EdgeInsets.all(14.0), child:
        Text('O',style: TextStyle(fontSize: 100,fontWeight: FontWeight.bold,color: Colors.blue,),textAlign: TextAlign.center,)); 
       
      }
    } else {
      return null;
    }
  }

  bool gameIsDone() {
    return allCellsAreTaken() || winner;
  }

  bool cellTaken (row,column) {
    return field[row][column].isNotEmpty;
  }

  bool allCellsAreTaken() {
    return field[0][0].isNotEmpty &&
        field[0][1].isNotEmpty &&
        field[0][2].isNotEmpty &&
        field[1][0].isNotEmpty &&
        field[1][1].isNotEmpty &&
        field[1][2].isNotEmpty &&
        field[2][0].isNotEmpty &&
        field[2][1].isNotEmpty &&
        field[2][2].isNotEmpty;
  }

  void winnerCheck() {
    String winnermessage;
    //check horizontal lines
    if (field[0][0].isNotEmpty &&
        field[0][0] == field[0][1] &&
        field[0][0] == field[0][2])
        {
          winner = true;
          winline = "Hor";
          winrow = 0;
          if (field[0][0] == playerChar) {
          winnermessage = "You Win";
          } else if (type==null) {
            winnermessage = "AI Win";
          } else {
            winnermessage = "You loose";
          }
    } else if (field[1][0].isNotEmpty &&
        field[1][0] == field[1][1] &&
        field[1][0] == field[1][2]) {
          winner = true;
          winline = "Hor";
          winrow = 1;
          if (field[1][0] == playerChar) {
          winnermessage = "You Win";
          } else if (type==null) {
            winnermessage = "AI Win";
          } else {
            winnermessage = "You loose";
          }
    } else if (field[2][0].isNotEmpty &&
        field[2][0] == field[2][1] &&
        field[2][0] == field[2][2]) {
          winner = true;
          winline = "Hor";
          winrow = 2;
          if (field[2][0] == playerChar) {
          winnermessage = "You Win";
          } else if (type==null) {
            winnermessage = "AI Win";
          } else {
            winnermessage = "You loose";
          }
    }

    //check vertical lines
    else if (field[0][0].isNotEmpty &&
        field[0][0] == field[1][0] &&
        field[0][0] == field[2][0]) {
          winner = true;
          winline = "Ver";
          wincol = 0;
          if (field[0][0] == playerChar) {
          winnermessage = "You Win";
          } else if (type==null) {
            winnermessage = "AI Win";
          } else {
            winnermessage = "You loose";
          }
    } else if (field[0][1].isNotEmpty &&
        field[0][1] == field[1][1] &&
        field[0][1] == field[2][1]) {
          winner = true;
          winline = "Ver";
          wincol = 1;
          if (field[0][1] == playerChar) {
          winnermessage = "You Win";
          } else if (type==null) {
            winnermessage = "AI Win";
          } else {
            winnermessage = "You loose";
          }
    } else if (field[0][2].isNotEmpty &&
        field[0][2] == field[1][2] &&
        field[0][2] == field[2][2]) {
          winner = true;
          winline = "Ver";
          wincol = 2;
          if (field[0][2] == playerChar) {
          winnermessage = "You Win";
          } else if (type==null) {
            winnermessage = "AI Win";
          } else {
            winnermessage = "You loose";
          }
    }

    //check diagonal
    else if (field[0][0].isNotEmpty &&
        field[0][0] == field[1][1] &&
        field[0][0] == field[2][2]) {
          winner = true;
          winline = "Dia_Des";          
          if (field[0][0] == playerChar) {
          winnermessage = "You Win";
          } else if (type==null) {
            winnermessage = "AI Win";
          } else {
            winnermessage = "You loose";
          }
    } else if (field[2][0].isNotEmpty &&
        field[2][0] == field[1][1] &&
        field[2][0] == field[0][2]) {
          winner = true;
          winline = "Dia_Asc";
          if (field[2][0] == playerChar) {
          winnermessage = "You Win";
          } else if (type==null) {
            winnermessage = "AI Win";
          } else {
            winnermessage = "You loose";
          }
    } else if (field[0][0].isNotEmpty &&
        field[0][1].isNotEmpty &&
        field[0][2].isNotEmpty &&
        field[1][0].isNotEmpty &&
        field[1][1].isNotEmpty &&
        field[1][2].isNotEmpty &&
        field[2][0].isNotEmpty &&
        field[2][1].isNotEmpty &&
        field[2][2].isNotEmpty) {
          winner = false;
          draft = true;
          winnermessage = "Draft";
    }

    if (winner || draft) {         
      showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(child: Text('Game Alert $winner')),
          content: Text(winnermessage),
          actions: <Widget> [
            FlatButton(
              child: Text('Retry'),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (type == null) {
                    setState(() {
                      winner = false; 
                      draft = false;                    
                      field = [
                        ['', '', ''],
                        ['', '', ''],
                        ['', '', '']
                      ];
                      playersTurn = true;
                    });
                  } else {
                    restart();
                  }
                }),            
            FlatButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      }
    );      
    }
  }

  // Restarting when playing online
  void restart() async {
    await FirebaseDatabase.instance
        .reference()
        .child('games')
        .child(gameId)
        .set(null);

    await FirebaseDatabase.instance
        .reference()
        .child('games')
        .child(gameId)
        .child('restart')
        .set(true);

    setState(() {
      cleanUp();
    });
  }

  void cleanUp() {
    winner = false;   
    field = [
      ['', '', ''],
      ['', '', ''],
      ['', '', '']
    ];
    playersTurn = me == 'X';
    String text = playersTurn ? 'Your turn' : 'Opponent\'s turn';
    print(text);
    Scaffold.of(_context).showSnackBar(SnackBar(content: Text(text)));
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