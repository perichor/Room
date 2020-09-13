extends Node

var udp = PacketPeerUDP.new();
var connected = false;

var SERVER_HOST: String = '127.0.0.1';
var PORT: int = 8081;

var ACKS = 32;

func _ready():
	udp.connect_to_host(SERVER_HOST, PORT);
	var buffer = PoolByteArray();
	buffer.append_array(poolU32Bit(2)); # seq
	buffer.append_array(poolU32Bit(50)); # ack
	buffer.append_array(poolU32Bit(4294967295)); # ack bitfield
	buffer.append(0); # message typeId
	buffer.append_array(poolU32Bit(2)); # message id
	buffer.append_array(poolU32Bit(5)); # message length
	buffer.append_array('Hello'.to_utf8()); # message
	udp.put_packet(buffer);
	
#func _process(_delta):

func writeUTF8String(buffer: PoolByteArray, string: String):
	buffer.append_array(string.to_utf8());
func readUTF8String(buffer: PoolByteArray):
	return buffer.get_string_from_utf8();
func writeU8BitInteger(buffer: PoolByteArray, integer: int):
	buffer.append(integer);
func writeU32BitInteger(buffer: PoolByteArray, integer: int):
	buffer.append_array(poolU32Bit(integer));
func writeU64BitInteger(buffer: PoolByteArray, integer: int):
	buffer.append_array(poolU64Bit(integer));
func readPoolInt(pool: PoolByteArray):
	var byteArray: Array = Array(pool);
	var integer: int = 0;
	for i in range(byteArray.size()):
		integer = integer << 8;
		integer += byteArray[i];
	return integer;
func poolU32Bit(integer: int):
	return poolUInt(integer, 32);
func poolU64Bit(integer: int):
	return poolUInt(integer, 64);
func poolUInt(integer: int, bitSize: int):
	var pool = PoolByteArray();
	for i in range(bitSize - 8, -1, -8):
		pool.append(integer >> i);
	return pool;
func readBitfield(bitfield: int, bitSize: int):
	var array = [];
	for i in range(bitSize, 0, -1):
		array.append(!!((bitfield >> (i - 1)) % 2));
	return array;
func writeBitfield(array: Array, bitSize: int):
	var bitfield = 0;
	for i in range(bitSize):
		bitfield = bitfield << 1;
		bitfield = bitfield + int(array[i]);
	return bitfield;
