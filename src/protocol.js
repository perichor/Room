var networking = require("./networking");

var PositionUpdate = exports.PositionUpdate = function (text) {
  this.text = text;
};

PositionUpdate.prototype = new networking.Message();
PositionUpdate.prototype.typeid = 0;

PositionUpdate.prototype.encode = function () { // not used???
  if (!this._buffer) {
    var dataBuf = new Buffer(this.text, "utf8");
    var sizeBuf = new Buffer(4);
    sizeBuf.writeUInt32BE(dataBuf.length, 0);
    this._buffer = Buffer.concat([sizeBuf, dataBuf]);
  }
  return this._buffer;
};

PositionUpdate.decode = function (buf) {
  var size = buf.readUInt32BE(0);
  var index = 4 + size;
  var text = buf.toString("utf8", 4, index);
  return [new PositionUpdate(text), index];
};

for (var k in exports) {
  if (exports.hasOwnProperty(k)) {
    var type = exports[k];
    networking.registerMessageType(type);
  }
}