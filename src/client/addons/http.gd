extends Node

var t = Thread.new()

func _init():
	var arg_bytes_loaded = {"name":"bytes_loaded","type":TYPE_INT}
	var arg_bytes_total = {"name":"bytes_total","type":TYPE_INT}
	var arg_result = {"name":"result","type":TYPE_RAW_ARRAY}
	var arg_headers = {"name":"responseHeaders","type":TYPE_DICTIONARY}
	var arg_url = {"name":"url","type":TYPE_STRING}
	add_user_signal("loading",[arg_bytes_loaded,arg_bytes_total,arg_url])
	add_user_signal("loaded",[arg_result,arg_headers,arg_url])
	add_user_signal("no_response", [arg_url])

func getRequest(domain, port, url, ssl, showProgress):
	if(t.is_active()):
		return
	t.start(self,"_load",{"domain": domain, "port": port, "url": url, "ssl": ssl, "showProgress": showProgress, "method": HTTPClient.METHOD_GET})
	
func postRequest(domain, port, url, body, ssl, showProgress):
	if(t.is_active()):
		return
	t.start(self,"_load",{"domain": domain, "port": port, "url": url, "ssl": ssl, "showProgress": showProgress, "method": HTTPClient.METHOD_POST,"body": body})
 
func _load(params):
# warning-ignore:unused_variable
	var err = 0
	var http = HTTPClient.new()
	err = http.connect_to_host(params.domain,params.port,params.ssl,false)
	while (http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING):
		http.poll()
		OS.delay_msec(100)

	var headers;

	if (params.has('body')):
		var body = JSON.print(params.body);
		headers = [
			"Content-Type: application/json",
			"Content-Length: " + str(body.length()),
			"Accept: application/json"
		]
		err = http.request(params.method,params.url,headers,body);
	else:
		headers = [
			"User-Agent: Pirulo/1.0 (Godot)",
			"Accept: */*"
		]
		err = http.request(params.method,params.url,headers);
		


	while (http.get_status() == HTTPClient.STATUS_REQUESTING):
		http.poll()
		OS.delay_msec(500)

	var rb = PoolByteArray()
	if (http.has_response()):
		var responseHeaders = http.get_response_headers_as_dictionary()
		while (http.get_status() == HTTPClient.STATUS_BODY):
			http.poll()
			var chunk = http.read_response_body_chunk()
			
			if(chunk.size() == 0):
				OS.delay_usec(1000)
			else:
				rb.append_array(chunk)
				if (params.showProgress):
					call_deferred("_send_loading_signal", rb.size(), http.get_response_body_length(), params.url)
		
		call_deferred("_send_loaded_signal", responseHeaders, params.url)
	else:
		call_deferred("_send_no_response_signal", params.url)
	http.close()
	return rb

# warning-ignore:shadowed_variable
func _send_loading_signal(l, t, url):
	emit_signal("loading", l, t, url)

func _send_loaded_signal(responseHeaders, url):
	var r = t.wait_to_finish()
	emit_signal("loaded", r, responseHeaders, url);

func _send_no_response_signal(url):
	t.wait_to_finish()
	emit_signal("no_response", url)

 # How to use:

# var http = preload('http.xml').instance()
# http.connect("loading",self,"_on_loading")
# http.connect("loaded",self,"_on_loaded")
# http.getHttp("http://example.com","/page?id=1",80,false) #domain,url,port,useSSL
# func _on_loading(loaded,total):
#    var percent = loaded*100/total
#func _on_loaded(result):
#    var result_string = result.get_string_from_ascii()
