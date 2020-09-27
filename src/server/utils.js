const usernameRegex = /^[a-zA-Z][a-zA-Z0-9_]{3,29}$/;

exports.isValidUsername = (username) => {
  return username && username.search(usernameRegex) !== -1;
};