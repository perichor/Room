extends Node

var bitUtils = preload('res://scripts/bit_utils.gd');

const ACKS: int = 32;

var seqLocal: int = 0; # latest sequence number sent
var messageId: int = 0; # latest messageId sent
var ackBitfieldLocal: int = 0; # last ACKS seq from server stored in bitfield

var seq: int = 0; # latest sequence number recieved
var ack: int = 0; # latest ack from server
var ackBitfield: int = 0; # last ACKS acks from server stored in bitfield

var udp = PacketPeerUDP.new();

func _init():
	if (global.SERVER_HOST == 'local' || global.SERVER_HOST == 'localhost'):
		global.SERVER_HOST = '127.0.0.1';
	udp.connect_to_host(global.SERVER_HOST, global.UDP_PORT);
	add_user_signal('playerUpdate');

func processPackets():
	if (udp.get_available_packet_count() > 0):
		while(udp.get_available_packet_count()):
			recievePacket();
	

func buildPlayerUpdatePacket(x, y, state):
	var message: PoolByteArray = PoolByteArray();
	message.append_array(bitUtils.poolU32Bit(x));
	message.append_array(bitUtils.poolU32Bit(y));
	message.append_array(bitUtils.poolU16Bit(state));
	udp.put_packet(buildUDPPacket(0, message));
	
func buildUDPPacket(messageType: int, message: PoolByteArray):
	incrementLocalSequence();
	incrementMessageId();
	var buffer = PoolByteArray();
	buffer.append_array(bitUtils.poolU32Bit(seqLocal)); # seq
	buffer.append_array(bitUtils.poolU32Bit(seq)); # ack
	buffer.append_array(bitUtils.poolU32Bit(ackBitfieldLocal)); # ack bitfield
	buffer.append_array(bitUtils.poolU32Bit(global.userId)); # user id
	buffer.append(messageType); # message typeId
	buffer.append_array(bitUtils.poolU32Bit(messageId)); # message id
	buffer.append_array(message); # message
#	print('Sent Packet Header', ' seq: ', seqLocal, ' ack: ', seq, ' bitfield: ', ackBitfieldLocal);
	return buffer;
	
func recieveRemotePlayerUpdate(message: PoolByteArray):
	var userId: int = bitUtils.readU32BitInt(message, 0);
	var x: int = bitUtils.readU32BitInt(message, 4);
	var y: int = bitUtils.readU32BitInt(message, 8);
	var state = bitUtils.readU16BitInt(message, 12);
	emit_signal('playerUpdate', userId, x, y, state)

func recievePacket():
	var packet: PoolByteArray = udp.get_packet();
	var packetSeq: int = bitUtils.readU32BitInt(packet, 0);
	var packetAck: int = bitUtils.readU32BitInt(packet, 4);
	var packetAckBitfield: int = bitUtils.readU32BitInt(packet, 8);
#	var serverId  = bitUtils.readU32BitInt(packet, 12);
	if (packetSeq >= seq - 1): # was causing issues when using > seq
		seq = packetSeq;
		ack = packetAck;
		ackBitfield = packetAckBitfield;
		if ((packet.size() - 16) > 0):
			var messagesBuffer: PoolByteArray = packet.subarray(16, (packet.size() - 1));
			if (messagesBuffer.size()):
				while (messagesBuffer.size()):
					var packetMessageType: int = bitUtils.readU8BitInt(messagesBuffer, 0);
	#				var packetMessageId: int = readU32BitInt(messagesBuffer, 1);
					if (packetMessageType == 1):
						recieveRemotePlayerUpdate(messagesBuffer.subarray(5, 18));
						if (messagesBuffer.size() > 19):
							messagesBuffer = messagesBuffer.subarray(19, messagesBuffer.size() - 1);
						else:
							messagesBuffer = PoolByteArray();
					else:
#						print('Message protocol unrecognized. Skipping rest of packet...');
						messagesBuffer = PoolByteArray();
						
func incrementLocalSequence():
	seqLocal = incrementU32BitInt(seqLocal);
func incrementMessageId():
	messageId = incrementU32BitInt(messageId);
func incrementU32BitInt(integer: int):
	if (integer == 4294967295):
		return 0;
	else:
		return integer + 1;

