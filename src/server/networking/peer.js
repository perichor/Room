var messaging = require('./messaging');
var timing = require('./timing');
var utils = require('./utils');

var EventEmitter = require('events').EventEmitter;

var Peer = module.exports = function Peer(id, address, port) {
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
  this.lastHandshake = timing.hrtime(); // time of last handshake
  this.userId = null; // user id recieving from peer
  
  this.EventEmitter = new EventEmitter();
};

Peer.prototype.send = function(msg) {
  msg.id = this.nextMessageId++;
  this.pendingMessages[msg.id] = msg;
};

Peer.prototype.recvMessage = function(msg) {
  if (!this.messageIdsReceived[msg.id]) {
    this.messageIdsReceived[msg.id] = true;
    this.emit('message', msg);
  }
};

Peer.prototype.recvPacket = function(seq, acks, userId) {
  if (this.userId === null) {
    this.userId = userId;
    this.emit('userConnected');
  }
  this.lastHandshake = timing.hrtime();
  this.seqsReceived[seq] = 1;
  if (utils.sequenceGreaterThan(seq, this.seq)) {
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

Peer.prototype.disconnect = function() {
  this.emit('disconnected');
  delete this;
}

Peer.prototype.emit = function() {
  this.EventEmitter.emit(...arguments);
}

Peer.prototype.on = function() {
  this.EventEmitter.on(...arguments);
}
