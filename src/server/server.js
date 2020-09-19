const childProcess = require('child_process');
var readline = require('readline');
var networking = require('./networking');
var protocol = require('./protocol');

var PORT = process.argv[2] | 4242;

var connection = networking.createConnection();

connection.on('listening', function() {
  console.log('Server is listening!', connection.listening);
});

var playerId = 0;

var players = {};

connection.on('peer', function(peer) {
  console.log('New connection from ' + peer.id);
  players[peer.id] = {
    peer: peer,
    id: playerId++,
    x: 88,
    y: 88
  }
  peer.on('message', function(msg) {
    if (msg instanceof protocol.PositionUpdate) {
      if (players[peer.id]) {
        players[peer.id].x = msg.x,
        players[peer.id].y = msg.y
        for (var i in players) {
          var toPlayer = players[i];
          for (var j in players) {
            var fromPlayer = players[j];
            if (toPlayer && fromPlayer && fromPlayer.peer.address !== toPlayer.peer.address) {
              toPlayer.peer.send(new protocol.PlayerUpdate(fromPlayer.id, fromPlayer.x, fromPlayer.y));
            }
          }
        }
      }
    }
  });
  peer.on('disconnected', function() {
    delete players[peer.id];
    console.log(peer.id + ' has disconnected');
  });
});
connection.listen(PORT);
connection.socket.unref();

var fileServer = childProcess.fork(__dirname + '/file-server.js');

// const net = require('net');
// var socketTCP = net.createServer();

// socketTCP.listen(PORT, function() {
//   console.log(`TCP Server On: ${PORT}`);
// });

// // When a client requests a connection with the server, the server creates a new
// // socket dedicated to that client.
// socketTCP.on('connection', function(socket) {
//     console.log('A new connection has been established.');

//     // Now that a TCP connection has been established, the server can send data to
//     // the client by writing to its socket.
//     socketTCP.write('Hello, client.');

//     // The server can also receive data from the client by reading from its socket.
//     socketTCP.on('data', function(chunk) {
//         console.log(`Data received from client: ${chunk.toString()}`);
//     });

//     // When the client requests to end the TCP connection with the server, the server
//     // ends the connection.
//     socketTCP.on('end', function() {
//         console.log('Closing connection with the client');
//     });

//     // Don't forget to catch error, for your own sake.
//     socketTCP.on('error', function(err) {
//         console.log(`Error: ${err}`);
//     });
// });

// server command-line interface
process.stdin.resume();
process.stdin.setEncoding('utf8');
var rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});
rl.on('line', function(line) {
  if (line == 'kill' || line == 'stop') {
    exitHandler.bind(null, { exit: true });
  }
  return null;
});
rl.on('SIGINT', function() { process.emit('SIGINT'); });
//do something when app is closing
process.on('exit', exitHandler.bind(null, {}));
//catches ctrl+c event
process.on('SIGINT', exitHandler.bind(null, { exit: true }));

function exitHandler(options, err) {
  if (options.exit) process.exit();
  console.log('Server shut down properly.');
  if (fileServer.kill()) {
    console.log('File server shut down properly.')
  }
}