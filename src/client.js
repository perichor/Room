var networking = require("./networking");
var protocol = require('./protocol');

var connection = networking.createConnection();
var server = connection.directConnect("127.0.0.1", 8081);

setInterval(function () {
    server.send(new protocol.TextMessage("HELO"));
}, 1000);

server.on("message", function (msg) {
  if (msg instanceof protocol.TextMessage) {
    console.log("Got text message: " + msg.text);
  } else {
    console.log("Got " + (typeof msg) + "!", msg);
  }
});

function exitHandler () {
    try { connection.close(); } catch (e) {}
}
process.on("exit", exitHandler);
process.on("SIGINT", exitHandler);