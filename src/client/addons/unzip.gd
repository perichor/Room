extends Resource

var storage_path
var zip_file
func unzip(sourceFile,destination):
	zip_file = sourceFile
	storage_path = destination + '/'
	var gdunzip = load('res://addons/gdunzip.gd').new()
	var loaded = gdunzip.load(zip_file)
	if !loaded:
		print('- Failed loading zip file')
		return false
# warning-ignore:return_value_discarded
	ProjectSettings.load_resource_pack(zip_file)
# warning-ignore:unused_variable
	var i = 0
	for f in gdunzip.files:
		unzip_file(f)
func unzip_file(fileName):
	var readFile = File.new()
	if readFile.file_exists("res://"+fileName):
		readFile.open(("res://"+fileName), File.READ)
		var content = readFile.get_buffer(readFile.get_len())
		readFile.close()
		var base_dir = storage_path + fileName.get_base_dir()
		var dir = Directory.new()
		dir.make_dir(base_dir)
		var writeFile = File.new()
		writeFile.open(storage_path + fileName, File.WRITE)
		writeFile.store_buffer(content)
		writeFile.close()

# how to use
# var Unzip = load('res://addons/gdunzip/unzip.gd').new()
# Unzip.unzip("zip file path","destination of extraction path")
