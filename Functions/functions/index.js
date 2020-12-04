const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp(functions.config().firebase);

exports.Invitation = functions.https.onRequest((request, response) => {
    const to = request.query.to;
    const fromId = request.query.fromId;
    const fromPushId = request.query.fromPushId;
    const fromName = request.query.fromName;
    const type = request.query.type;
    var paylod;

    if (type === 'invite') {
            payload = {
            notification: { title: 'Game invite', body: `${fromName} invites you to play!`},
            data: { click_action: "FLUTTER_NOTIFICATION_CLICK",fromId: fromId,fromPushId: fromPushId,fromName: fromName,type: type}       
        };
        }   else {
            payload = {
                notification: { title: 'Game invite', body: `${fromName} accepted your invitation!`},
                data: { click_action: "FLUTTER_NOTIFICATION_CLICK",fromId: fromId,fromPushId: fromPushId,fromName: fromName,type: type}       
            }; 
        }    
    
    var options = {
        priority: "high",
        timeToLive: 60 * 60 * 24
        };
                
     admin.messaging().sendToDevice(to, payload, options)
        .then(function(response) {
            console.log("Successfully sent message:", response);
            return;
        })
        .catch(function(error) {
            console.log("Error sending message:", error);
        });
});
