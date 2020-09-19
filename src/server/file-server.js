const http = require('http');
const fs = require('fs');
const path = require('path');
var metadata = require('../../package.json');
var readline = require('readline');

var PORT = process.argv[2] | 4243;

const requestListener = function (req, res) {
  if (req.url === '/download') {
    var filePath = path.join(__dirname, '/dist/Room.zip');
    var file = fs.statSync(filePath);
    res.writeHead(200, {
        'Content-Type': 'application/zip',
        'Content-Length': file.size
    });
    var readStream = fs.createReadStream(filePath);
    readStream.pipe(res);
  } else if (req.url === '/version') {
    res.writeHead(200);
    res.end(metadata.version);
  } else {
    res.writeHead(400);
    res.end();
  }
}

const server = http.createServer(requestListener);
server.listen(PORT);
console.log('File Server is Listening on port:', PORT, 'with client version:', metadata.version);

// catch kill from parent process
process.on('SIGTERM', exitHandler.bind(null, { exit: true }));

function exitHandler(options, err) {
  if (options.exit) process.exit();
}