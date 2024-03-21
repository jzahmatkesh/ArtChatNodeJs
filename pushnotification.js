const admin = require('firebase-admin');
const serviceAccount = require('./artchat-dbdb7-firebase-adminsdk-exlp0-2d197752ba.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: 'https://artchat-dbdb7.firebaseio.com'
});

// const registrationToken = 'flnrUOT7I0pvol8JcSV9WO:APA91bFhnJ4IXU3Ia516AmmZO_4oHpvDTIgSf0pzFJT1wfDl12X1V7KaS1pEREVTS04ytA5P81sr0E8RROxyThmnPAoFpgnadujDKyDi7_SGRgx5bUqvLGE9BFVZlTJfQvzVXKQDlaca';


async function pushnotification(token, title, note, info) {
    try {
        const message = {
            notification: {
                title: title,
                body: note,
            },
            apns: {
                headers: {
                    "apns-priority": "10",
                },
                payload: {
                    aps: {
                        sound: "default",
                    },
                },
            },
            android: {
                notification: {
                    sound: "default",
                },
            },
            data: {
                "sender": `${info.from || 0}`,
                "fromfamily": `${info.fromfamily || 0}`,
                "fromimg": `${info.fromimg || 0}`
            },
            token: token
        };

        var res = await admin.messaging().send(message);
    }
    catch (err) {
        console.log(`error send push: ${err}`);
    }
}

// .then((response) => {
//     console.log('Successfully sent message:', response);
// })
// .catch((error) => {
//     console.error('Error sending message:', error);
// });


module.exports = {
    pushnotification
}
