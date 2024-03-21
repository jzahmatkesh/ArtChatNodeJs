const helper = require('../helper');
const config = require('../config');
const sql = require('mssql');
const socket = require('../wbsocket').default;
var crypto = require('crypto');
var email = require('../mailsender');
var google = require('./google');

async function getData(header) {
    await sql.connect(config.sqlConfig)
    const rows = await sql.query`Exec PrcUsers ${header.host},${header['sec-ch-ua'] + ' - ' + header['user-agent']},${header.token},${header.family}`
    const data = helper.emptyOrRows(rows['recordsets']);
    return data[0]
}

async function authenticate(header, user) {
    await sql.connect(config.sqlConfig)
    const rows = await sql.query`Exec PrcAuthenticate ${header.host},${header['sec-ch-ua'] + ' - ' + header['user-agent']},${user.email},${user.password}`
    const data = helper.emptyOrRows(rows['recordsets']);
    return data[0]
}

async function verifybytoken(header, user) {
    await sql.connect(config.sqlConfig)
    const rows = await sql.query`Exec PrcVerifyByToken ${header.host},${header['sec-ch-ua'] + ' - ' + header['user-agent']},${user.token}`
    const data = helper.emptyOrRows(rows['recordsets']);
    return data[0]
}

async function googleVerify(header, user) {
    var gid = await google.verifyGoogle(user.idtoken);
    await sql.connect(config.sqlConfig)
    const rows = await sql.query`Exec PrcVerifyByGoogle ${header.host},${header['sec-ch-ua'] + ' - ' + header['user-agent']}, ${user.email}, ${user.family}, ${gid}, ${user.idtoken}, ${user.googleimg}`;
    const data = helper.emptyOrRows(rows['recordsets']);
    return data[0]
}

async function register(header, user) {
    checkonly = 1;
    if ("id" in user && user.id > 0) {
        checkonly = 0;
    }
    if ("emailconfirmcode" in user && "hash" in user) {
        checkonly = 0;
        var hash = crypto.createHash('md5').update(user.emailconfirmcode).digest('hex');
        if (hash != user.hash) {
            throw new Error('cofirmation code is not correct');
        }
    }
    await sql.connect(config.sqlConfig)
    const rows = await sql.query`Exec PrcRegister ${header.host},${header['sec-ch-ua'] + ' - ' + header['user-agent']},${user.id},${user.family},${user.mobile},${user.email},${user.password},${user.img},${checkonly}`
    const data = helper.emptyOrRows(rows['recordsets']);
    if (checkonly == 1) {
        const rnd = Math.floor(Math.random() * 90000) + 10000;
        console.log(`your code: ${rnd}`);
        var hash = crypto.createHash('md5').update(rnd.toString()).digest('hex');
        if (await email.sendMail(user.email, 'Mobile Confirmation code', `your activatio code is ${rnd}`))
            return [{ 'hash': hash }];
        else {
            throw new Error('خطا در ارسال پست  الکترونیک - مجددا سعی کنید');
        }
    }
    return data[0];
}

async function getFriends(header) {
    await sql.connect(config.sqlConfig)
    const rows = await sql.query`Exec PrcFriends ${header.host},${header['sec-ch-ua'] + ' - ' + header['user-agent']},${header.token}`
    const data = helper.emptyOrRows(rows['recordsets']);
    return data[0]
}

async function findFriends(header, family) {
    await sql.connect(config.sqlConfig)
    const rows = await sql.query`Exec PrcFindFriends ${header.host},${header['sec-ch-ua'] + ' - ' + header['user-agent']},${header.token},${family}`
    const data = helper.emptyOrRows(rows['recordsets']);
    return data[0]
}

async function getAvatars(header) {
    await sql.connect(config.sqlConfig)
    const rows = await sql.query`Exec PrcLoadAvatars ${header.host},${header['sec-ch-ua'] + ' - ' + header['user-agent']},${header.token}`
    const data = helper.emptyOrRows(rows['recordsets']);
    return data[0]
}

module.exports = {
    getData,
    authenticate,
    verifybytoken,
    googleVerify,
    register,
    getFriends,
    findFriends,
    getAvatars
}