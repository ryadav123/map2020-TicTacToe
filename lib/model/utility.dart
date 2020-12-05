String getValue(Map<String, dynamic> message, String key) {
  print('Inside util function....\n');
  print('Value of map....\n');
  print(message);
  print('\nValue of key....$key\n');
  print('\n\n\n');
  var result;
  //message.forEach((k, value) {
   // print('k=$k\n');
   // print('value=$value\n');
    final notification = message['notification'];
    final data = message['data'];
    if(key=='type' ) {
      result = data['type'];
    }
    if (key == 'fromId' ) {
      result = data['fromId'];
    }
    if (key == 'fromPushId' ) {
      result = data['fromPushId'];
    }
    if (key == 'fromName' ) {
      result = data['fromName'];
    }
    //}
    // if (value[key] == key) {
    //   print('Inside if..\n');
    //   result = value[key];
    // }
    return result;

  }
  
