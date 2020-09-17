extends Node

var bitUtils = preload('res://scripts/bit_utils.gd');
var playerResource = preload('res://scenes/player.tscn');

var udp = PacketPeerUDP.new();

onready var localPlayer = get_node('player');
var remotePlayers = {};

func _ready():
	udp.connect_to_host(global.SERVER_HOST, global.PORT);

func _process(_delta):
	buildPositionUpdatePacket();
	if (udp.get_available_packet_count() > 0):
		while(udp.get_available_packet_count()):
			recievePacket();

func getPlayerStatusById(playerId):
	return remotePlayers[playerId];	

func recievePacket():
	var packet: PoolByteArray = udp.get_packet();
	var packetSeq: int = bitUtils.readU32BitInt(packet, 0);
	var packetAck: int = bitUtils.readU32BitInt(packet, 4);
	var packetAckBitfield: int = bitUtils.readU32BitInt(packet, 8);
	if (packetSeq >= global.seq - 1): # was causing issues when using > seq
		global.seq = packetSeq;
		global.ack = packetAck;
		global.ackBitfield = packetAckBitfield;
		if ((packet.size() - 12) > 0):
			var messagesBuffer: PoolByteArray = packet.subarray(12, (packet.size() - 1));
			if (messagesBuffer.size()):
				while (messagesBuffer.size()):
					var packetMessageType: int = bitUtils.readU8BitInt(messagesBuffer, 0);
	#				var packetMessageId: int = readU32BitInt(messagesBuffer, 1);
					if (packetMessageType == 1):
						handlePlayerUpdate(messagesBuffer.subarray(5, 16));
						if (messagesBuffer.size() > 17):
							messagesBuffer = messagesBuffer.subarray(17, messagesBuffer.size() - 1);
						else:
							messagesBuffer = PoolByteArray();
					else:
#						print('Message protocol unrecognized. Skipping rest of packet...');
						messagesBuffer = PoolByteArray();

func handlePlayerUpdate(message: PoolByteArray):
	var playerId: int = bitUtils.readU32BitInt(message, 0);
	var x: int = bitUtils.readU32BitInt(message, 4);
	var y: int = bitUtils.readU32BitInt(message, 8);
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
	message.append_array(bitUtils.poolU32Bit(x));
	message.append_array(bitUtils.poolU32Bit(y));
	udp.put_packet(buildUDPPacket(0, message));
	
func buildUDPPacket(messageType: int, message: PoolByteArray):
	incrementLocalSequence();
	incrementMessageId();
	var buffer = PoolByteArray();
	buffer.append_array(bitUtils.poolU32Bit(global.seqLocal)); # seq
	buffer.append_array(bitUtils.poolU32Bit(global.seq)); # ack
	buffer.append_array(bitUtils.poolU32Bit(global.ackBitfieldLocal)); # ack bitfield
	buffer.append(messageType); # message typeId
	buffer.append_array(bitUtils.poolU32Bit(global.messageId)); # message id
	buffer.append_array(message); # message
#	print('Sent Packet Header', ' seq: ', seqLocal, ' ack: ', seq, ' bitfield: ', ackBitfieldLocal);
	return buffer;
	
func incrementLocalSequence():
	global.seqLocal = incrementU32BitInt(global.seqLocal);
func incrementMessageId():
	global.messageId = incrementU32BitInt(global.messageId);
func incrementU32BitInt(integer: int):
	if (integer == 4294967295):
		return 0;
	else:
		return integer + 1;
