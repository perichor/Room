var networking = require('./networking');

var PositionUpdate = exports.PositionUpdate = function (x, y) {
  this.x = x;
  this.y = y;
};

PositionUpdate.prototype = new networking.Message();
PositionUpdate.prototype.typeid = 0;

PositionUpdate.prototype.encode = function () {
  if (!this._buffer) {
    var dataBuf = new Buffer(8);
    dataBuf.writeUInt32BE(this.x, 0);
    dataBuf.writeUInt32BE(this.y, 4);
    this._buffer = dataBuf;
  }
  return this._buffer;
};

PositionUpdate.decode = function (buf) {
  var x = buf.readUInt32BE(0);
  var y = buf.readUInt32BE(4);
  return [new PositionUpdate(x, y), 8];
};


var PlayerUpdate = exports.PlayerUpdate = function (playerId, x, y) {
  this.playerId = playerId;
  this.x = x;
  this.y = y;
};

PlayerUpdate.prototype = new networking.Message();
PlayerUpdate.prototype.typeid = 1;

PlayerUpdate.prototype.encode = function () {
  if (!this._buffer) {
    var dataBuf = new Buffer(12);
    dataBuf.writeUInt32BE(this.playerId, 0);
    dataBuf.writeUInt32BE(this.x, 4);
    dataBuf.writeUInt32BE(this.y, 8);
    this._buffer = dataBuf;
  }
  return this._buffer;
};

PlayerUpdate.decode = function (buf) {
  var playerId = buf.readUInt32BE(0);
  var x = buf.readUInt32BE(4);
  var y = buf.readUInt32BE(12);
  return [new PlayerUpdate(playerId, x, y), 12];
};

for (var k in exports) {
  if (exports.hasOwnProperty(k)) {
    var type = exports[k];
    networking.registerMessageType(type);
  }
}