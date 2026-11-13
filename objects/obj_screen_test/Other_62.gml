show_debug_message("Async HTTP Event - BEGIN");

var names = ds_map_keys_to_array(async_load);
array_foreach(names, function(el, idx){
	show_debug_message($"{el} = {async_load[? el]}");
});

if (ds_map_find_value(async_load, "id") == req_id) {
	var status = async_load[? "status"];
	var http_status = async_load[? "http_status"];
	if(status==0 && http_status==200) {
		var result = async_load[? "result"]; // is a filename
		var buffer = buffer_load(result);
		if(buffer!=-1) {
			text_file_content = buffer_read(buffer, buffer_text);
			buffer_delete(buffer);
			show_debug_message($"Info: File '{result}' loaded.");
		} else {
			show_debug_message($"Error: Failed to open {result}.");
			text_file_content = "<failed>";
		}
	} else {
		var url = async_load[? "url"];
		show_debug_message($"Error: Can not load file {url}. HTTP status - {http_status}.");
		text_file_content = "<failed>";
	}
}

show_debug_message("Async HTTP Event - END");

