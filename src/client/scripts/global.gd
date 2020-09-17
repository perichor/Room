extends Node

var SERVER_HOST: String;
var PORT: int = 4242;

const ACKS: int = 32;

var seqLocal: int = 0; # latest sequence number sent
var messageId: int = 0; # latest messageId sent
var ackBitfieldLocal: int = 0; # last ACKS seq from server stored in bitfield

var seq: int = 0; # latest sequence number recieved
var ack: int = 0; # latest ack from server
var ackBitfield: int = 0; # last ACKS acks from server stored in bitfield
