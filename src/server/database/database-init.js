const mysql = require('mysql');
const options = require('./mysql-options.js');
const connection = mysql.createConnection(options);

var initQueries = module.exports = [
  `CREATE SCHEMA IF NOT EXISTS room`,
  `USE room`,
  `CREATE TABLE IF NOT EXISTS users(
      id int primary key auto_increment,
      username varchar(30),
      hashed_password varchar(64),
      x int,
      y int,
      locale int
  )`
]

connection.connect(err => {
  if (err) {
    console.error('An error occurred while connecting to the DB')
    throw err
  }

  initQueries.forEach((query) => {
    connection.query(query, function(err, results, fields) {
      if (err) {
        console.log(err.message);
      }
    });
  });

  connection.end(function(err) {
    if (err) {
      return console.log(err.message);
    }
  });
});