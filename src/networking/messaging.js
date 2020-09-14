var Bitfield = require('bitfield');

var ACKS = exports.ACKS = 32;   // number of acknowledges of previously received packets
var MESSAGE_BUFFER_SIZE = exports.MESSAGE_BUFFER_SIZE = 256;   // Length of individual message buffer in packets

var messageTypes = {};

exports.registerMessageType = function (type) {
  var typeid = type.prototype.typeid;
  var oldtype = messageTypes[typeid];
  if (oldtype) {
    throw new Error('Networking message type with id=' + typeid + ' already exists: ' + oldtype.name);
  }
  messageTypes[typeid] = type;
};

// base class for all your message types
var Message = exports.Message = function Message () {
  this.id = null;
  this.sent = null;
  this._buffer = null;
  this.retryDelay = 0;
  this.typeid = 0;
};

exports.encodeMessage = function (msg) {
  var msgHeader = new Buffer(5);
  msgHeader.writeUInt8(msg.typeid, 0);
  msgHeader.writeUInt32BE(msg.id, 1);
  var buf = msg.encode();
  return Buffer.concat([msgHeader, buf]);
};

exports.decodeMessage = function (buf) {
  var typeid = buf.readUInt8(0);
  var id = buf.readUInt32BE(1);
  var type = messageTypes[typeid];
  if (type) { 
    var decoded = type.decode(buf.slice(5));
    var msg = decoded[0];
    var index = decoded[1];
    msg.id = id;
    return [msg, index + 5];
  } else {
    console.error('Could not find message type with id=' + typeid)
  }
};

exports.encodeHeader = function (seq, peer) {
  // >>> 0 casts to uint32
  seq = seq >>> 0;          // packet seq
  var ack = peer.seq >>> 0; // peer.seq we received for sure (it's seq of the latest packet received)
  var head = new Buffer(8);
  head.writeUInt32BE(seq, 0);
  head.writeUInt32BE(ack, 4);
  var acksField = new Bitfield(ACKS); // bitfield contains ack status for ACKS packets before peer.seq
  for (var i = ack - 1, j = 0; j < ACKS; i--, j++) {
    if (peer.seqsReceived[i]) {
      acksField.set(j, 1);
    }
  }
  return Buffer.concat([head, acksField.buffer])
};

exports.decodeHeader = function (buf) {
  var seq = buf.readUInt32BE(0);
  var ack = buf.readUInt32BE(4);
  var acksStart = 8;
  var acksEnd = 8 + ACKS / 8;
  var acksField = new Bitfield(buf.slice(acksStart, acksEnd));
  var acks = new Array(ACKS + 1);
  acks[0] = ack;
  for (var i = ack - 1, j = 0; j < ACKS; i--, j++) {
    if (acksField.get(j)) acks[j + 1] = i;
  }
  return [seq, acks, buf.slice(acksEnd)];
};
