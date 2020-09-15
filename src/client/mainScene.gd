extends Node

var udp = PacketPeerUDP.new();
var connected = false;

const ACKS: int = 32;

var SERVER_HOST: String = '104.34.146.138';
var PORT: int = 4242;

var seqLocal: int = 0; # latest sequence number sent
var messageId: int = 0; # latest messageId sent
var ackBitfieldLocal: int = 0; # last ACKS seq from server stored in bitfield

var seq: int = 0; # latest sequence number recieved
var ack: int = 0; # latest ack from server
var ackBitfield: int = 0; # last ACKS acks from server stored in bitfield

var playerResource = preload("res://player.tscn");

onready var localPlayer = get_node('player');

var remotePlayers = {};

func _ready():
	udp.connect_to_host(SERVER_HOST, PORT);

func _process(_delta):
	buildPositionUpdatePacket();
	if (udp.get_available_packet_count() > 0):
		while(udp.get_available_packet_count()):
			recievePacket();

func getPlayerStatusById(playerId):
	return remotePlayers[playerId];	

func recievePacket():
	var packet: PoolByteArray = udp.get_packet();
	var packetSeq: int = readU32BitInt(packet, 0);
	var packetAck: int = readU32BitInt(packet, 4);
	var packetAckBitfield: int = readU32BitInt(packet, 8);
	if (packetSeq >= seq - 1): # was causing issues when using > seq
		seq = packetSeq;
		ack = packetAck;
		ackBitfield = packetAckBitfield;
		if ((packet.size() - 12) > 0):
			var messagesBuffer: PoolByteArray = packet.subarray(12, (packet.size() - 1));
			if (messagesBuffer.size()):
				while (messagesBuffer.size()):
					var packetMessageType: int = readU8BitInt(messagesBuffer, 0);
	#				var packetMessageId: int = readU32BitInt(messagesBuffer, 1);
					if (packetMessageType == 1):
						handlePlayerUpdate(messagesBuffer.subarray(5, 16));
						if (messagesBuffer.size() > 17):
							messagesBuffer = messagesBuffer.subarray(17, messagesBuffer.size() - 1);
						else:
							messagesBuffer = PoolByteArray();
					else:
						print('Message Protocol Unrecognized. Skipping Packet...');
						messagesBuffer = PoolByteArray();

func handlePlayerUpdate(message: PoolByteArray):
	var playerId: int = readU32BitInt(message, 0);
	var x: int = readU32BitInt(message, 4);
	var y: int = readU32BitInt(message, 8);
	if (!remotePlayers.has(playerId)):
		var newPlayer = playerResource.instance();
		remotePlayers[playerId] = {
			'playerId': playerId,
			'x': x,
			'y': y,
			'lastHandshakeTime': OS.get_ticks_msec()
		}
		newPlayer.setRemotePlayerId(playerId);
		self.add_child(newPlayer);
	else:
		remotePlayers[playerId].x = x;
		remotePlayers[playerId].y = y;
		remotePlayers[playerId].lastHandshakeTime = OS.get_ticks_msec();

func buildPositionUpdatePacket():
	var x: int = int(round(localPlayer.position[0]));
	var y: int = int(round(localPlayer.position[1]));
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
func readU8BitInt(pool: PoolByteArray, index: int):
	return readPoolInt(pool.subarray(index, index));
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
