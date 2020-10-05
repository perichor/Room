const Promise = require('bluebird');

const mysql = require('mysql');
const options = require('./mysql-options.js');

const init = require('./database-init');

var Database = module.exports = function Database() {

  options.database = 'room';
  options.connectionLimit = 20;

  this.pool = mysql.createPool(options);
  this.queryList(init);
}

Database.prototype.end = function() {
  this.pool.end(function(err) {
    if (err) {
      return console.log(err.message);
    }
  });
}

Database.prototype.queryList = function(queries) {
  var queryResults = [];
  queries.forEach((query) => {
    queryResults.push(this.query(query));
  });
  return Promise.all(queryResults);
}

Database.prototype.query = function(query) {
  return new Promise((resolve, reject) => {
    this.pool.getConnection((err, connection) => {
      connection.query(query, function(err, result, fields) {
        err ? reject(err) : resolve(result[0]);
        connection.release();
      });
    });
  }).catch((err) => {
    console.log(err)
  });
}


Database.prototype.createAccount = function(username, password) {
  return this.query(`INSERT INTO users(username, hashed_password, char_name)
                     VALUES ('${username}','${password}','${username}')`);
}

Database.prototype.getUserFromLogin = function(username, password) {
  return this.query(`SELECT * FROM users 
                     WHERE username = '${username}' AND hashed_password = '${password}'`);
}

Database.prototype.getUserInfoFromId = function(userId) {
  return this.query(`SELECT char_name FROM users 
                     WHERE id = ${userId}`);
}

Database.prototype.usernameInUse = function(username) {
  return this.query(`SELECT * FROM users WHERE username = '${username}'`).then((result) => !!result);
}

Database.prototype.updateUserLocations = function(users) {
  if (users && users.length) {
    var xQuery = 'UPDATE users SET x = CASE id';
    var yQuery = 'UPDATE users SET y = CASE id';
    var localeQuery = 'UPDATE users SET locale = CASE id';
    var ids = '';
    users.forEach((user) => {
      if (ids) {
        ids = ids + `,${user.id}`
      } else {
        ids = `(${user.id}`
      }
      xQuery += ` WHEN ${user.id} THEN ${user.x !== null && user.x !== undefined ? user.x : 88}`
      yQuery += ` WHEN ${user.id} THEN ${user.y !== null && user.y !== undefined ? user.y : 88}`
      localeQuery += ` WHEN ${user.id} THEN ${user.locale || 0}`
    });
    ids = ids + ')';
    return this.queryList([`${xQuery} ELSE x END WHERE id in ${ids}`, `${yQuery} ELSE y END WHERE id in ${ids}`, `${localeQuery} ELSE locale END WHERE id in ${ids}`]);
  }
}
