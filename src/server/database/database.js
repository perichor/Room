const Promise = require('bluebird');

const mysql = require('mysql');
const options = require('./mysql-options.js');

const init = require('./database-init');

var Database = module.exports = function Database() {

  options.database = 'room';
  options.connectionLimit = 10;

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
      });
    });
  });
}


Database.prototype.createAccount = function(username, password) {
  return this.query(`INSERT INTO users(username, hashed_password)
              VALUES ('${username}','${password}')`);
}

Database.prototype.getUserInfo = function(username, password) {
  return this.query(`SELECT * FROM users 
                     WHERE username = '${username}' AND hashed_password = '${password}'`);
}

Database.prototype.usernameInUse = function(username) {
  return this.query(`SELECT * FROM users WHERE username = '${username}'`).then((result) => !!result);
}
