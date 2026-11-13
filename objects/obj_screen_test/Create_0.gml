text_file_content = "";
req_id = -1;

load_file = function(path) {
	var baseurl = NOGX_get_base_url();
	show_debug_message($"Info: load_file");
	show_debug_message({ baseurl, path });
	req_id = http_get_file($"{baseurl}/{path}", path);
	if(req_id==-1) {
		show_debug_message("Error: http_get_file failed");
	}
}

load_file("html5game/test.txt");

