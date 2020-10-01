const childProcess = require('child_process');
var readline = require('readline');
var networking = require('./networking');
var protocol = require('./protocol');
var gameState = require('./game-state');

var db = require('./database');

var TICK_RATE = 15;   // Server tick rate
var DB_UPDATE_RATE = 4000;   // Update DB every n ticks (4000 = 1 minute)

var PORT = process.argv[2] | 4242;

var connection = networking.createConnection();

connection.on('listening', () => {
  console.log(`Main Server is listening on port ${connection.listening.port}`);
});

connection.on('peer', (peer) => {
  console.log(`New connection from ${peer.id}`);

  peer.on('userConnected', () => {
    console.log(`Peer at ${peer.id} connected as user: ${peer.userId}`);
    gameState.userConnected(peer);
    httpsServer.send(`connect:${peer.userId}`)
  });

  peer.on('message', function(msg) {
    if (msg instanceof protocol.PlayerUpdate) {
      gameState.updateUserIfConnected(peer.userId, msg);
    }
  });

  peer.on('disconnected', () => {
    gameState.userDisconnected(peer.userId);
    httpsServer.send(`disconnect:${peer.userId}`)
    console.log(`${peer.id} has disconnected`);
  });
});

var tickCount = 0;

var serverTickInterval = setInterval(() => {
  gameState.forEveryUser((toUser) => {
    gameState.forEveryUser((fromUser) => {
      if (toUser && fromUser && fromUser.peer.id !== toUser.peer.id) {
        toUser.peer.send(new protocol.RemotePlayerUpdate(fromUser.id, fromUser.x, fromUser.y));
      }
    });
  });

  if (tickCount === DB_UPDATE_RATE) { // Executes every DB_UPDATE_RATE ticks    
    db.updateUserLocations(gameState.getAllUsersList());
    tickCount = -1;
  }

  connection.sendPackets();
  tickCount++;
}, TICK_RATE);

connection.listen(PORT);
connection.socket.unref();

var httpsServer = childProcess.fork(__dirname + '/https-server.js');

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
  clearInterval(serverTickInterval);
  db.end();
  console.log('Server shut down properly.');
  if (httpsServer.kill()) {
    console.log('File server shut down properly.')
  }
}