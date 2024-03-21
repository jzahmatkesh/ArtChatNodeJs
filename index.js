const config = require('./config');
const sql = require('mssql');
const fs = require('fs');
const path = require('path');
const express = require('express');
const cors = require('cors');
require('./wbsocket');
const crypto = require('crypto');
const app = express();
// const ffmpegStatic = require('ffmpeg-static');
// const ffmpeg = require('fluent-ffmpeg');
const ffmpegInstaller = require('@ffmpeg-installer/ffmpeg');
const ffmpeg = require('fluent-ffmpeg');

ffmpeg.setFfmpegPath(ffmpegInstaller.path);

app.use(cors())


const port = 3030; //process.env.PORT || 3000;
const usersRoute = require('./routes/users');


function getRandomName(extension) {
    // Generate a random 8-character string for the filename
    const randomString = crypto.randomBytes(4).toString('hex');

    // Get the current timestamp to make the filename unique
    const timestamp = Date.now();

    // Combine the random string, timestamp, and extension to form the filename
    const filename = `${randomString}_${timestamp}.${extension}`;

    return filename;
}

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/user', usersRoute);

const bodyParser = require('body-parser');
function changeExtension(file, extension) {
    const basename = path.basename(file, path.extname(file))
    return path.join(path.dirname(file), basename + extension)
}
// const { file } = require('pdfkit');

// Use the 'body-parser' middleware to parse raw binary data.
app.use(bodyParser.raw({ type: '*/*', limit: '10mb' })); // Adjust the limit as needed.

app.get('/', (req, res) => {
    res.json({ 'message': 'You are connected to Mystery World Back-end' });
})
app.get("/preview/:id", async (req, res) => {
    if (req.params.id == "notfound") {
        res.sendFile(path.join(__dirname, "images", "notfound.png"));
    }
    try {
        await sql.connect(config.sqlConfig);
        const rows = await sql.query`Exec PrcGetFileName ${req.params.id}`;
        if (rows.recordset.length > 0) {
            const filename = path.join(__dirname, "images", rows.recordset[0].filename);
            if (fs.existsSync(filename)) {
                // if (filename.toString().toLowerCase().includes('.m4a') || filename.toString().toLowerCase().includes('.mp3')) {
                //     res.sendFile(filename, (err) => {
                //         if (err) {
                //             res.status(err.status || 500).send('Error sending file.');
                //         }
                //     });
                // }
                // else {
                res.sendFile(filename);
                // }
            }
            else {
                res.sendFile(path.join(__dirname, "images", "notfound.png"));
            }
        }
        else {
            res.sendFile(path.join(__dirname, "images", "notfound.png"));
        }
    }
    catch (err) {
        console.error('error getting file', err);
    }
});
app.post('/upload', async (req, res) => {
    const receivedData = req.body; // This will contain your Uint8List data as raw binary data.

    var filename = getRandomName(req.headers.extension);

    try {
        await sql.connect(config.sqlConfig);
        const rows = await sql.query`Exec PrcGetFileName ${req.headers.unique}`;
        if (rows.recordset.length > 0) {
            filename = rows.recordset[0].filename;
        }
    }
    catch (e) { }

    const pth = path.join(__dirname, 'images', filename);
    fs.writeFile(`${pth}`, receivedData, async (err) => {
        if (err) {
            res.status(500).send('{"Error" : "Error saving data to file"}');
        } else {
            convertaudio(pth, changeExtension(pth, ".mp3"));
            try {
                const rows = await sql.query`Exec PrcAddImage ${req.headers.token}, ${req.headers.type}, ${req.headers.id}, ${req.headers.idx}, ${changeExtension(filename, '.mp3')}`;
                res.status(200).send(`{"unique": "${rows.recordset[0].Unique}", "chatid": "${rows.recordset[0].ChatID}"}`);
            }
            catch (e) {
                console.log(`{"Error" : "Error saving data to database ${e}"}`);
                res.status(500).send(`{"Error" : "Error saving data to database ${e}"}`);
            }
        }
    });
    // res.status(200).send('Data received successfully'); // Send a response back to the Flutter app.
});


/* Error handler middleware */
app.use((err, req, res, next) => {
    const statusCode = err.statusCode || 500;
    console.error(err.message, err.stack);
    res.status(statusCode).json({ 'message': err.message });
    return;
});



app.listen(port, () => {
    console.log(`ArtAd Rest Api running at http://localhost:${port}`)
});


function convertaudio(from, to) {
    ffmpeg.setFfmpegPath(ffmpegStatic);
    ffmpeg()
        .input(from)
        .outputOptions('-ab', '192k')
        .saveToFile(to)
        .on('progress', (progress) => {
            if (progress.percent) {
                console.log(`Processing: ${Math.floor(progress.percent)}% done`);
            }
        })
        .on('end', () => {
            console.log('FFmpeg has finished.');
            fs.unlink(from, (err) => {
                if (err) {
                    console.error(err);
                } else {
                    console.log('File is deleted.');
                }
            });
        })
        .on('error', (error) => {
            console.error(error);
        });
}