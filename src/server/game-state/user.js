const Promise = require('bluebird');
const EventEmitter = require('events').EventEmitter;
// const utils = require('../utils');

var User = module.exports = function User(peer, x, y, locale) {
  this.id = peer.userId;
  this.x = x;
  this.y = y;
  this.locale = locale;
  this.peer = peer;

  this.EventEmitter = new EventEmitter();
}

User.prototype.emit = function() {
  this.EventEmitter.emit(...arguments);
}

User.prototype.on = function() {
  this.EventEmitter.on(...arguments);
}
