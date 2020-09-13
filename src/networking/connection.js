var dgram = require('dgram');
var EventEmitter = require('events').EventEmitter;

var Peer = require('./peer');
var hrtime = require('./timing').hrtime;
var messaging = require('./messaging');

var RATE = 15;   // packet sending loop interval delay (ms)
var PMAX = 1200; // maximum packet size (bytes). 1400 is known as common MTU

var Connection = module.exports = function Connection() {
  this.socket = dgram.createSocket('udp4');
  this.peers = {};

  this.socket.on('close', function () { clearInterval(this.peerUpdateInterval); }.bind(this));
  this.socket.on('error', function (e) { console.log('Network socket error!'); throw e; });

  this.socket.on('message', function (data, remote) {
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
    var decoded = messaging.decodeHeader(data);
    var seq = decoded[0];
    var acks = decoded[1];
    var messagesBuf = decoded[2];
    peer.recvPacket(seq, acks);
    if (peer.seq <= seq) { // Only recieve packet messages if packet is latest
      while (messagesBuf.length) {
        var parts = messaging.decodeMessage(messagesBuf);
        if (parts && parts.length) {
          var msg = parts[0];
          messagesBuf = messagesBuf.slice(parts[1]);
          peer.recvMessage(msg);
        } else {
          messagesBuf = false;
        }
      } 
    }
  }.bind(this));

  this.peerUpdateInterval = setInterval(function () {
    // Generate and send packets to all peers on interval RATE
    var curtime = hrtime();
    for (var p in this.peers) {
      var peer = this.peers[p];
      var msg;

      var seq = peer.seqLocal++;
      var headerBuf = messaging.encodeHeader(seq, peer);

      var messagesForThisPacket = {};
      for (var m in peer.pendingMessages) {
        msg = peer.pendingMessages[m];

        var sent = msg.sent;
        if (!sent) {
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
        for (var i = 0, ii = msgBufs.length; i < ii; ++i) {
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
  }.bind(this), RATE);
};

Connection.prototype = new EventEmitter();
Connection.prototype.constructor = Connection;

Connection.prototype.close = function () {
  this.socket.close();
};

Connection.prototype.directConnect = function (address, port) {
  var id = generatePeerId(address, port);
  var peer = new Peer(id, address, port);
  this.peers[id] = peer;
  return peer;
};

Connection.prototype.rawSend = function (packet, peer) {
  return this.socket.send(packet, 0, packet.length, peer.port, peer.address);
};

Connection.prototype.listen = function (port) {
  this.socket.on('listening', function () {
    this.listening = this.socket.address();
    this.emit('listening');
  }.bind(this));
  this.socket.bind(port);
};

function generatePeerId (address, port) {
  return address + ':' + port;
}
