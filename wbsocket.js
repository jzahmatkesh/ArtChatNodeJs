import { Server, OPEN } from 'ws';
import User from './datamodel/user';
import { sqlConfig } from './config';
import { connect, query } from 'mssql';
import { pushnotification } from './pushnotification';

const wss = new Server({ port: 8090 });


const dataModel = [];

// Function to check if a class exists in the list
function userAlreadyOnline(id) {
    for (let i = dataModel.length - 1; i >= 0; i--) {
        if (dataModel[i] instanceof User && dataModel[i].id === id) {
            dataModel.splice(i, 1);
        }
    }
    return false;
}

function broadcast(msg, ids) {
    for (let i = dataModel.length - 1; i >= 0; i--) {
        if (dataModel[i].ws.readyState === OPEN && (ids.length == 0 || ids.includes(dataModel[i].id))) {
            dataModel[i].ws.send(msg);
        }
    }
}

function broadcastonlineUsers() {
    const ids = [];
    for (let i = dataModel.length - 1; i >= 0; i--) {
        ids.push(dataModel[i].id);
    }
    for (let i = dataModel.length - 1; i >= 0; i--) {
        if (dataModel[i].ws.readyState === OPEN && (ids.length == 0 || ids.includes(dataModel[i].id))) {
            dataModel[i].ws.send(JSON.stringify({ 'onlineusers': ids }));
        }
    }
}


wss.on('connection', (ws, req) => {
    ws.on('message', (message) => {
        const obj = JSON.parse(message);
        if (obj.imonline && obj.id && obj.family) {
            userAlreadyOnline(obj.id);
            dataModel.push(new User(ws, obj.id, obj.family, obj.img));
            broadcastonlineUsers();
        }
        else if (obj.type == "Chat") {
            Chat(ws, obj);
        }
        else if (obj.type == "ChatAttach") {
            ChatAttach(ws, obj);
        }
        else if (obj.type == "ChatTyping") {
            ChatTyping(ws, obj);
        }
        else if (obj.type == "ChatLike") {
            ChatLike(ws, obj);
        }
        else if (obj.fcmtoken) {
            // ws.send(JSON.stringify({ "fcmtokn": obj.fcmtoken }));
            updateFCmToken(obj);
        }
        else if (obj.type == "ChatSeen") {
            seenChat(obj);
        }
        else if (obj.type == "DelChat") {
            delChat(ws, obj);
        }
        else if (obj.sendnotification) {
            sendpushnotification(ws, obj);
        }
        else {
            ws.send(JSON.stringify({ "error": `message not found ${message}` }));
        }
    });

    ws.on('close', (reasonCode, description) => {
        for (let i = dataModel.length - 1; i >= 0; i--) {
            if (dataModel[i].ws === ws) {
                dataModel.splice(i, 1);
            }
        }
        broadcastonlineUsers();
        // broadcast(JSON.stringify({ 'onlineusers': dataModel }));
    });
});

async function Chat(ws, obj) {
    try {
        await connect(sqlConfig);
        const rows = await query`Exec PrcChat ${obj.token},${obj.from},${obj.to},${obj.msg}`;
        if (rows.recordset.length > 0) {
            if (obj.to > 100) {
                broadcast(
                    JSON.stringify({ 'id': rows.recordset[0].ID, 'type': 'Chat', 'from': obj.from, 'fromfamily': obj.fromfamily, 'fromimg': obj.fromimg, 'msg': obj.msg, 'to': obj.to }),
                    [obj.from, obj.to]
                );
                sendpushnotification(ws, { 'tofcmtoken': rows.recordset[0].FcmToken, 'title': rows.recordset[0].FromFamily, 'note': rows.recordset[0].Msg, 'from': obj.from, 'fromfamily': obj.fromfamily, 'fromimg': obj.fromimg });
            }
            else {
                const members = rows.recordset[0].GrpMembers.substring(1).split(",");
                var mem = [];
                for (let i = 0; i < members.length; i++) {
                    mem.push(parseInt(members[i]));
                }
                broadcast(
                    JSON.stringify({ 'id': rows.recordset[0].ID, 'type': 'Chat', 'from': obj.from, 'fromfamily': obj.fromfamily, 'fromimg': obj.fromimg, 'msg': obj.msg, 'to': obj.to }),
                    mem
                );
            }
        }
    }
    catch (e) {
        console.log(`Exec PrcLogError 'chat message ', ${e.message}`);
        await query`Exec PrcLogError 'chat message ', ${e.message}`;
        ws.send(JSON.stringify({ 'error': 'خطا در ثبت پیام' }));
    }
}

async function delChat(ws, obj) {
    try {
        await connect(sqlConfig);
        const rows = await query`Exec PrcDelChat ${obj.token},${obj.id}`;
        if (rows.recordset.length > 0) {
            const members = rows.recordset[0].GrpMembers.substring(1).split(",");
            var mem = [];
            for (let i = 0; i < members.length; i++) {
                mem.push(parseInt(members[i]));
            }
            broadcast(
                JSON.stringify({ 'type': 'DelChat', 'id': obj.id }),
                mem
            );
        }
    }
    catch (e) {
        console.log(`Exec PrcLogError 'Delete chat message ', ${e.message}`);
        await query`Exec PrcLogError 'Delete chat message ', ${e.message}`;
        ws.send(JSON.stringify({ 'error': 'خطا در حذف پیام' }));
    }
}

async function ChatAttach(ws, obj) {
    try {
        await connect(sqlConfig);
        const rows = await query`Exec PrcChatByID ${obj.id}`;
        if (rows.recordset.length > 0) {
            if (rows.recordset[0].To > 100) {
                broadcast(
                    JSON.stringify({ 'id': obj.id, 'type': 'Chat', 'from': rows.recordset[0].From, 'fromfamily': rows.recordset[0].FromFamily, 'fromimg': rows.recordset[0].FromImg, 'msg': rows.recordset[0].Msg, 'to': rows.recordset[0].To, 'unique': rows.recordset[0].Unique, 'extension': rows.recordset[0].Extension }),
                    [rows.recordset[0].From, rows.recordset[0].To]
                );
            }
            else {
                const members = rows.recordset[0].GrpMembers.substring(1).split(",");
                var mem = [];
                for (let i = 0; i < members.length; i++) {
                    mem.push(parseInt(members[i]));
                }
                broadcast(
                    JSON.stringify({ 'id': obj.id, 'type': 'Chat', 'from': rows.recordset[0].From, 'fromfamily': rows.recordset[0].FromFamily, 'fromimg': rows.recordset[0].FromImg, 'msg': rows.recordset[0].Msg, 'to': rows.recordset[0].To, 'unique': rows.recordset[0].Unique, 'extension': rows.recordset[0].Extension }),
                    mem
                );
            }
        }
    }
    catch (e) {
        console.log(`Exec PrcLogError 'chat attach ', ${e.message}`);
        await query`Exec PrcLogError 'chat attach ', ${e.message}`;
        ws.send(JSON.stringify({ 'error': 'خطا در ارسال پیام فایل' }));
    }
}

async function ChatTyping(ws, obj) {
    try {
        broadcast(
            JSON.stringify({ 'type': 'ChatTyping', 'from': obj.from, 'to': obj.to }),
            [obj.to]
        );
    }
    catch (e) {
        console.log(`Exec PrcLogError 'chat Typing ', ${e.message}`);
        await query`Exec PrcLogError 'chat typing ', ${e.message}`;
    }
}

async function ChatLike(ws, obj) {
    try {
        await connect(sqlConfig);
        const rows = await query`Exec PrcChatLike ${obj.token},${obj.id},${obj.kind}`;
        if (rows.recordset.length > 0) {
            if (rows.recordset[0].To > 100) {
                broadcast(
                    JSON.stringify({ 'id': rows.recordset[0].ID, 'type': 'ChatLike', 'kind1': rows.recordset[0].Kind1, 'kind2': rows.recordset[0].Kind2, 'kind3': rows.recordset[0].Kind3, 'kind4': rows.recordset[0].Kind4, 'kind5': rows.recordset[0].Kind5, 'kind6': rows.recordset[0].Kind6 }),
                    [rows.recordset[0].To, rows.recordset[0].From]
                );
            }
            else {
                const members = rows.recordset[0].GrpMembers.substring(1).split(",");
                var mem = [];
                for (let i = 0; i < members.length; i++) {
                    mem.push(parseInt(members[i]));
                }
                broadcast(
                    JSON.stringify({ 'id': rows.recordset[0].ID, 'type': 'ChatLike', 'kind1': rows.recordset[0].Kind1, 'kind2': rows.recordset[0].Kind2, 'kind3': rows.recordset[0].Kind3, 'kind4': rows.recordset[0].Kind4, 'kind5': rows.recordset[0].Kind5, 'kind6': rows.recordset[0].Kind6 }),
                    mem
                );
            }
        }
    }
    catch (e) {
        console.log(`Exec PrcLogError 'chat Like ', ${e.message}`);
        await query`Exec PrcLogError 'chat Like ', ${e.message}`;
        ws.send(JSON.stringify({ 'error': 'خطا در ثبت تغییرات پیام' }));
    }
}

async function updateFCmToken(obj) {
    try {
        await connect(sqlConfig);
        await query`Exec PrcUpdateFcmToken ${obj.fcmtoken},${obj.token}`;
    }
    catch (e) {
        console.log(`Exec PrcLogError 'update fcm token', ${e.message}`);
        await query`Exec PrcLogError 'update fcm token', ${e.message}`;
    }
}

async function sendpushnotification(ws, obj) {
    try {
        if (obj.tofcmtoken) {
            pushnotification(obj.tofcmtoken, obj.title, obj.note, obj);
        }
        // else {
        //     await sql.connect(config.sqlConfig);
        //     const rows = await sql.query`Exec PrcFcmTokens ${obj.token},0`;
        //     if (rows.recordset.length > 0) {
        //         rows.recordset.map(record => pushnotif.pushnotification(record.FcmToken, obj.title, obj.note));
        //     }
        // }
    }
    catch (e) {
        ws.send(JSON.stringify({ 'onlinesupport': 1, 'type': 'error', 'msg': `${e.message}` }));
        await query`Exec PrcLogError 'request online support', ${e.message}`;
    }
}

async function seenChat(obj) {
    if (obj.from > 100 && obj.to > 100)
        try {
            await connect(sqlConfig);
            await query`Exec PrcSeenChat ${obj.from},${obj.to}`;
        }
        catch (e) {
            console.log(`Exec PrcLogError 'seen chat', ${e.message}`);
            await query`Exec PrcLogError 'seen chat', ${e.message}`;
        }
}

export default {
    broadcast
}
