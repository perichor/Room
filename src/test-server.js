var dgram = require("dgram");
var PORT = 8081;

var connection = dgram.createSocket("udp4");

connection.on('message', function (msg, remote) {
  var address = remote.address;
  var port = remote.port;
  var peerId = address + ":" + port;

  console.log(msg);
  console.log(msg.readUInt8(0));
  console.log(msg.readUInt32BE(1));
});

connection.bind(PORT);

console.log(`Listening on port: ${PORT}`);