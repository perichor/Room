var networking = require('./networking');

// Recieves posit
var PlayerUpdate = exports.PlayerUpdate = function (x, y, state) {
  this.x = x;
  this.y = y;
  this.state = state;
};

PlayerUpdate.prototype = new networking.Message();
PlayerUpdate.prototype.typeid = 0;

PlayerUpdate.prototype.encode = function () {
  if (!this._buffer) {
    var dataBuf = new Buffer.alloc(10);
    dataBuf.writeUInt32BE(this.x, 0);
    dataBuf.writeUInt32BE(this.y, 4);
    dataBuf.writeUInt16BE(this.state, 8);
    this._buffer = dataBuf;
  }
  return this._buffer;
};

PlayerUpdate.decode = function (buf) {
  var x = buf.readUInt32BE(0);
  var y = buf.readUInt32BE(4);
  var state = buf.readUInt16BE(8);
  return [new PlayerUpdate(x, y, state), 10];
};



// Used to notify client of remote player status
var RemotePlayerUpdate = exports.RemotePlayerUpdate = function (userId, x, y, state) {
  this.userId = userId;
  this.x = x;
  this.y = y;
  this.state = state;
};

RemotePlayerUpdate.prototype = new networking.Message();
RemotePlayerUpdate.prototype.typeid = 1;

RemotePlayerUpdate.prototype.encode = function () {
  if (!this._buffer) {
    var dataBuf = new Buffer.alloc(14);
    dataBuf.writeUInt32BE(this.userId, 0);
    dataBuf.writeUInt32BE(this.x, 4);
    dataBuf.writeUInt32BE(this.y, 8);
    dataBuf.writeUInt16BE(this.state, 12);
    this._buffer = dataBuf;
  }
  return this._buffer;
};

RemotePlayerUpdate.decode = function (buf) {
  var userId = buf.readUInt32BE(0);
  var x = buf.readUInt32BE(4);
  var y = buf.readUInt32BE(8);
  var state = buf.readUInt16BE(12);
  return [new RemotePlayerUpdate(userId, x, y, state), 14];
};

for (var k in exports) {
  if (exports.hasOwnProperty(k)) {
    var type = exports[k];
    networking.registerMessageType(type);
  }
}