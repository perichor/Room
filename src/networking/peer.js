var messaging = require('./messaging');

var EventEmitter = require('events').EventEmitter;

var Peer = module.exports = function Peer (id, address, port) {
  this.id = id;
  this.address = address;
  this.port = port;
  this.nextMessageId = 0;
  this.seq = -1;                // latest remote seq
  this.seqLocal = 0;            // seq of the next sent packet
  this.seqsReceived = {};       // acks i.e. received sequences
  this.messageIdsReceived = {}; // used to filter duplicate messages (how to clean this up?)
  this.pendingMessages = {};    // will be considered to send on next flush
  this.messageIdsBySeq = {};    // used to ack messages when packet is acked
};

Peer.prototype = new EventEmitter();
Peer.prototype.constructor = Peer;

Peer.prototype.send = function (msg) {
  msg.id = this.nextMessageId++;
  this.pendingMessages[msg.id] = msg;
};

Peer.prototype.recvMessage = function (msg) {
  if (!this.messageIdsReceived[msg.id]) {
    this.messageIdsReceived[msg.id] = true;
    this.emit('message', msg);
  }
};

Peer.prototype.recvPacket = function (seq, acks) {
  this.seqsReceived[seq] = 1;
  if (seq > this.seq || this.seq < 0) {
    this.seq = seq;
    // cleanup old acks
    var tooOld = seq - messaging.ACKS;
    for (var ackdSeq in this.seqsReceived) {
      if (ackdSeq < tooOld) {
        delete this.seqsReceived[ackdSeq];
      }
    }
  }
  // ack messages from acked packets
  for (var i = 0; i < acks.length; ++i) {
    var messageIds = this.messageIdsBySeq[acks[i]];
    if (messageIds) {
      for (var j = 0; j < messageIds.length; ++j) {
        var messageId = messageIds[j];
        delete this.pendingMessages[messageId];
        this.emit('ack', messageId);
      }
      delete this.messageIdsBySeq[acks[i]];
    }
  }
}
