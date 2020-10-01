var dgram = require('dgram');
var EventEmitter = require('events').EventEmitter;

var Peer = require('./peer');
var hrtime = require('./timing').hrtime;
var messaging = require('./messaging');
var utils = require('./utils');

var PMAX = 1200; // maximum packet size (bytes). 1400 is known as common MTU

var DISCONNECT_TIMEOUT = 5000; // mills since last packet to disconnect

var Connection = module.exports = function Connection() {
  this.socket = dgram.createSocket('udp4');
  this.peers = {};

  this.socket.on('error', function(e) { console.log('Network socket error!'); throw e; });

  this.socket.on('message', function(data, remote) {
    var address = remote.address;
    var port = remote.port;
    var peerId = address + ':' + port;
    var peer = this.peers[peerId];
    if (!peer) {
      // New connection
      this.peers[peerId] = peer = new Peer(peerId, address, port);
      this.emit('peer', peer);
    }

    // Decode packet
    var header = messaging.decodeHeader(data);
    peer.recvPacket(header.seq, header.acks, header.userId);
    if (peer.seq === header.seq) { // Only recieve packet messages if packet is latest
      while (header.messagesBuf.length) {
        var parts = messaging.decodeMessage(header.messagesBuf);
        if (parts && parts.length) {
          var msg = parts[0];
          header.messagesBuf = header.messagesBuf.slice(parts[1]);
          peer.recvMessage(msg);
        } else {
          header.messagesBuf = false;
        }
      } 
    }
  }.bind(this));
};

Connection.prototype = new EventEmitter();
Connection.prototype.constructor = Connection;

Connection.prototype.sendPackets = function() {
  // Build packets from queued messages and send to all peers
  var curtime = hrtime();
  for (var p in this.peers) {
    var peer = this.peers[p];
    var msg;

    if ((curtime - peer.lastHandshake) > DISCONNECT_TIMEOUT) {
      delete this.peers[p];
      peer.disconnect();
    }

    var seq = peer.seqLocal++;
    var headerBuf = messaging.encodeHeader(seq, peer);

    var messagesForThisPacket = {};
    for (var m in peer.pendingMessages) {
      msg = peer.pendingMessages[m];

      if (!msg.sent) {
        messagesForThisPacket[msg.id] = msg;
      }
    }

    // collect buffers for this packet
    var bufs = [headerBuf];
    var messageIds = [];
    var size = headerBuf.length;
    for (var k in messagesForThisPacket) {
      msg = messagesForThisPacket[k];
      var msgBufs = messaging.encodeMessage(msg);
      for (var i = 0; i < msgBufs.length; ++i) {
        size += msgBufs[i].length;
      }
      if (size > PMAX) {
        // can't fit message to this packet
        break;
      }
      msg.sent = curtime;
      bufs.push(msgBufs);
      messageIds.push(msg.id);
    }
    peer.messageIdsBySeq[seq] = messageIds;
    this.rawSend(Buffer.concat(bufs), peer);
  }
}

Connection.prototype.close = function() {
  this.socket.close();
};

Connection.prototype.directConnect = function(address, port) {
  var id = generatePeerId(address, port);
  var peer = new Peer(id, address, port);
  this.peers[id] = peer;
  return peer;
};

Connection.prototype.rawSend = function(packet, peer) {
  return this.socket.send(packet, 0, packet.length, peer.port, peer.address);
};

Connection.prototype.listen = function(port) {
  this.socket.on('listening', function() {
    this.listening = this.socket.address();
    this.emit('listening');
  }.bind(this));
  this.socket.bind(port);
};

function generatePeerId (address, port) {
  return address + ':' + port;
}
