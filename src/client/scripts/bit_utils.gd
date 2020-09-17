extends Resource

static func writeUTF8String(buffer: PoolByteArray, string: String):
	buffer.append_array(string.to_utf8());
static func readUTF8String(buffer: PoolByteArray):
	return buffer.get_string_from_utf8();
static func writeU8BitInteger(buffer: PoolByteArray, integer: int):
	buffer.append(integer);
static func writeU32BitInteger(buffer: PoolByteArray, integer: int):
	buffer.append_array(poolU32Bit(integer));
static func writeU64BitInteger(buffer: PoolByteArray, integer: int):
	buffer.append_array(poolU64Bit(integer));
static func readU32BitInt(pool: PoolByteArray, index: int):
	return readPoolInt(pool.subarray(index, index + 3));
static func readU64BitInt(pool: PoolByteArray, index: int):
	return readPoolInt(pool.subarray(index, index + 7));
static func readU8BitInt(pool: PoolByteArray, index: int):
	return readPoolInt(pool.subarray(index, index));
static func readPoolInt(pool: PoolByteArray):
	var byteArray: Array = Array(pool);
	var integer: int = 0;
	for i in range(byteArray.size()):
		integer = integer << 8;
		integer += byteArray[i];
	return integer;
static func poolU32Bit(integer: int):
	return poolUInt(integer, 32);
static func poolU64Bit(integer: int):
	return poolUInt(integer, 64);
static func poolUInt(integer: int, bitSize: int):
	var pool = PoolByteArray();
	for i in range(bitSize - 8, -1, -8):
		pool.append(integer >> i);
	return pool;
static func readBitfield(bitfield: int, bitSize: int):
	var array = [];
	for i in range(bitSize, 0, -1):
		array.append(!!((bitfield >> (i - 1)) % 2));
	return array;
static func writeBitfield(array: Array, bitSize: int):
	var bitfield = 0;
	for i in range(bitSize):
		bitfield = bitfield << 1;
		bitfield = bitfield + int(array[i]);
	return bitfield;
