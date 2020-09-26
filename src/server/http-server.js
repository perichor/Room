const https = require('https');
const fs = require('fs');
const path = require('path');
const readline = require('readline');
const express = require('express');

var privateKey  = fs.readFileSync(__dirname + '/sslcert/selfsigned.key');
var certificate = fs.readFileSync(__dirname + '/sslcert/selfsigned.crt');

var credentials = {key: privateKey, cert: certificate};

const metadata = require('../../package.json');

const PORT = process.argv[2] | 4243;

const server = express();

var users = {};

server.use(
  express.urlencoded({
    extended: true
  })
)

server.use(express.json())

server.get('/download', (req, res) => {
  var filePath = path.join(__dirname, '/dist/Room.zip');
  var file = fs.statSync(filePath);
  res.writeHead(200, {
      'Content-Type': 'application/zip',
      'Content-Length': file.size
  });
  var readStream = fs.createReadStream(filePath);
  readStream.pipe(res);
});

server.get('/version', (req, res) => {
  res.writeHead(200);
  res.end(metadata.version);
});


server.post('/create-account', (req, res) => {
  var username = req.body.username;
  var password = req.body.password;
  res.writeHead(200);
  if (!users[username]) {
    users[username] = {
      username: username,
      password: password
    }
    res.end('success');
  } else {
    res.end('failed');
  }
});

server.post('/login', (req, res) => {
  var username = req.body.username;
  var password = req.body.password;
  res.writeHead(200);
  if (users[username] && users[username].password === password) {
    res.end('success');  
  } else {
    res.end('failed');
  }
});

var httpsServer = https.createServer({
    key: privateKey,
    cert: certificate,
    passphrase: 'roomssl'
}, server);

httpsServer.listen(PORT);
console.log('HTTPS Server is Listening on port:', PORT, 'with client version:', metadata.version);


// catch kill from parent process
process.on('SIGTERM', exitHandler.bind(null, { exit: true }));

function exitHandler(options, err) {
  if (options.exit) process.exit();
}