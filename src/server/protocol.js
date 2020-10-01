var networking = require('./networking');

// Recieves posit
var PlayerUpdate = exports.PlayerUpdate = function (x, y) {
  this.x = x;
  this.y = y;
};

PlayerUpdate.prototype = new networking.Message();
PlayerUpdate.prototype.typeid = 0;

PlayerUpdate.prototype.encode = function () {
  if (!this._buffer) {
    var dataBuf = new Buffer.alloc(8);
    dataBuf.writeUInt32BE(this.x, 0);
    dataBuf.writeUInt32BE(this.y, 4);
    this._buffer = dataBuf;
  }
  return this._buffer;
};

PlayerUpdate.decode = function (buf) {
  var x = buf.readUInt32BE(0);
  var y = buf.readUInt32BE(4);
  return [new PlayerUpdate(x, y), 8];
};



// Used to notify client of remote player status
var RemotePlayerUpdate = exports.RemotePlayerUpdate = function (userId, x, y) {
  this.userId = userId;
  this.x = x;
  this.y = y;
};

RemotePlayerUpdate.prototype = new networking.Message();
RemotePlayerUpdate.prototype.typeid = 1;

RemotePlayerUpdate.prototype.encode = function () {
  if (!this._buffer) {
    var dataBuf = new Buffer.alloc(12);
    dataBuf.writeUInt32BE(this.userId, 0);
    dataBuf.writeUInt32BE(this.x, 4);
    dataBuf.writeUInt32BE(this.y, 8);
    this._buffer = dataBuf;
  }
  return this._buffer;
};

RemotePlayerUpdate.decode = function (buf) {
  var userId = buf.readUInt32BE(0);
  var x = buf.readUInt32BE(4);
  var y = buf.readUInt32BE(8);
  return [new RemotePlayerUpdate(userId, x, y), 12];
};

for (var k in exports) {
  if (exports.hasOwnProperty(k)) {
    var type = exports[k];
    networking.registerMessageType(type);
  }
}