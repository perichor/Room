var readline = require('readline');
var networking = require('../networking');
var protocol = require('../protocol');

var PORT = process.argv[2] | 8081;

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
          for (var j in players) {
            var player = players[j];
            if (i !== j && player) {
              players[i].peer.send(new protocol.PlayerUpdate(player.id, player.x, player.y));
            }
          }
        }
      }
    }
  });
  peer.on('disconnected', function() {
    if (players[peer.id]) { // ISSUE: Double event handler trigger needs cleanup
      delete players[peer.id];
      console.log(peer.id + ' has disconnected');
    }
  });
});
connection.listen(PORT);
connection.socket.unref();

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
}