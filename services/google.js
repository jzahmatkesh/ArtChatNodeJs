const { OAuth2Client } = require('google-auth-library');
const client = new OAuth2Client();

async function verifyGoogle(token) {
    const ticket = await client.verifyIdToken({
        idToken: token,
        audience: "271366162425-dff4iqglkn5qtulgf8ac7hnoup13k7ss.apps.googleusercontent.com",  // Specify the CLIENT_ID of the app that accesses the backend
    });
    const payload = ticket.getPayload();
    const userid = payload['sub'];

    return userid;
}



module.exports = {
    verifyGoogle
}
