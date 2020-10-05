const Promise = require('bluebird');
const EventEmitter = require('events').EventEmitter;
const User = require('./user');
// const utils = require('../utils');

var GameState = module.exports = function GameState() {
  this.users = {};

  this.EventEmitter = new EventEmitter();
}

GameState.prototype.userConnected = function(peer) {
  this.users[peer.userId] = new User(peer);
};

GameState.prototype.userDisconnected = function(userId) {
  delete this.users[userId];
};

GameState.prototype.updateUserIfConnected = function(userId, msg) {
  if (this.users[userId]) {
    this.users[userId].x = msg.x;
    this.users[userId].y = msg.y;
    this.users[userId].state = msg.state;
  }
}

GameState.prototype.forEveryUser = function(callback) {
  for (var id in this.users) {
    if (id && this.users[id]) {
      callback(this.users[id]);
    }
  }
}

GameState.prototype.getUser = function(id) {
  return this.users[id];
}

GameState.prototype.getAllUsersList = function() {
  // unoptimal memeory usage. Think about refactor
  var list = [];
  for (var id in this.users) {
    list.push(this.users[id]);
  }
  return list;
}

GameState.prototype.emit = function() {
  this.EventEmitter.emit(...arguments);
}

GameState.prototype.on = function() {
  this.EventEmitter.on(...arguments);
}
