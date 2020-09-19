module.exports.sequenceGreaterThan = function (s1, s2) {
  return ( ( s1 > s2 ) && ( s1 - s2 <= 2147483647 ) ) || 
         ( ( s1 < s2 ) && ( s2 - s1  > 2147483647 ) );
}