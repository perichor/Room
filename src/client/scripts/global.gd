extends Node

var build_version: String = metadata.version;

var SERVER_HOST: String = 'local';
var UDP_PORT: int = 4242;
var HTTP_PORT: int = 4243;

var defaultPosition: Vector2 = Vector2(88, 88);

var userId: int;
var initialPosition: Vector2;
