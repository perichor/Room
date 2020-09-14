extends Node

var udp = PacketPeerUDP.new();
var connected = false;

const ACKS: int = 32;

var SERVER_HOST: String = '127.0.0.1';
var PORT: int = 8081;

var seqLocal: int = 0; # latest sequence number sent
var messageId: int = 0; # latest messageId sent
var ackBitfieldLocal: int = 0; # last ACKS seq from server stored in bitfield

var seq: int = 0; # latest sequence number recieved
var ack: int = 0; # latest ack from server
var ackBitfield: int = 0; # last ACKS acks from server stored in bitfield

onready var player = get_node('player');

func _ready():
	udp.connect_to_host(SERVER_HOST, PORT);

func _process(_delta):
	buildPositionUpdatePacket();
	if udp.get_available_packet_count() > 0:
		recievePacket();

func recievePacket():
	var packet: PoolByteArray = udp.get_packet();
	var packetSeq: int = readPoolInt(packet.subarray(0, 3));
	var packetAck: int = readPoolInt(packet.subarray(4, 7));
	var packetAckBitfield: int = readPoolInt(packet.subarray(8, 11));
#	print('Recieved Packet Header', ' seq: ', packetSeq, ' ack: ', packetAck, ' bitfield: ', packetAckBitfield);
	if (packetSeq >= seq - 1):
		seq = packetSeq;
		ack = packetAck;
		ackBitfield = packetAckBitfield;
		if ((packet.size() - 12) > 0):
			var messagesBuffer: PoolByteArray = packet.subarray(12, (packet.size() - 1));
			while (messagesBuffer.size()):
				var packetMessageType: int = readPoolInt(messagesBuffer.subarray(0, 0));
				var packetMessageId: int = readPoolInt(messagesBuffer.subarray(1, 4));
#				print('Message Recieved', ' messageTypeId=', packetMessageType, ' messageId=', packetMessageId);
				if (packetMessageType == 1):
					handlePlayerUpdate(messagesBuffer.subarray(5, 12));
				if (messagesBuffer.size() > 13):
					messagesBuffer = messagesBuffer.subarray(13, messagesBuffer.size() - 1);
				else:
					messagesBuffer = PoolByteArray();

func handlePlayerUpdate(message: PoolByteArray):
	print(Array(message));

func buildPositionUpdatePacket():
	var x: int = int(round(player.position[0]));
	var y: int = int(round(player.position[1]));
	var message: PoolByteArray = PoolByteArray();
	message.append_array(poolU32Bit(x));
	message.append_array(poolU32Bit(y));
	udp.put_packet(buildUDPPacket(0, message));
	
func buildUDPPacket(messageType: int, message: PoolByteArray):
	incrementLocalSequence();
	incrementMessageId();
	var buffer = PoolByteArray();
	buffer.append_array(poolU32Bit(seqLocal)); # seq
	buffer.append_array(poolU32Bit(seq)); # ack
	buffer.append_array(poolU32Bit(ackBitfieldLocal)); # ack bitfield
	buffer.append(messageType); # message typeId
	buffer.append_array(poolU32Bit(messageId)); # message id
	buffer.append_array(message); # message
#	print('Sent Packet Header', ' seq: ', seqLocal, ' ack: ', seq, ' bitfield: ', ackBitfieldLocal);
	return buffer;
	
func incrementLocalSequence():
	seqLocal = incrementU32BitInt(seqLocal);
func incrementMessageId():
	messageId = incrementU32BitInt(messageId);
func incrementU32BitInt(integer: int):
	if (integer == 4294967295):
		return 0;
	else:
		return integer + 1;

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
func readU32BitInt(pool: PoolByteArray, index: int):
	return readPoolInt(pool.subarray(index, index + 3));
func readU64BitInt(pool: PoolByteArray, index: int):
	return readPoolInt(pool.subarray(index, index + 7));
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
