const nodemailer = require("nodemailer");

const transporter = nodemailer.createTransport({
    host: "smtp.gmail.com",
    port: 465,
    secure: true,
    auth: {
        user: 'treasurehunt.hazineavi@gmail.com',
        pass: 'ptmmwjdfkbgnquys'
    }
});

async function sendMail(email, subject, body) {
    const info = await transporter.sendMail({
        from: `"CEO" treasurehunt.hazineavi@gmail.comv`,
        to: email,
        subject: subject,
        text: body,
        //   html: "<b>Hello world?</b>", // html body
    }).catch(console.error);
    console.log(`to ${email} - text ${body}`);
    return info ? info.messageId : null;
}

module.exports = {
    sendMail
}
