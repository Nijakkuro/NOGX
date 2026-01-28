var gw = display_get_gui_width();
var gh = display_get_gui_height();
draw_sprite_stretched(spr_screen_test, 1, 0, 0, gw, gh);


for(var i=0; i<10; i++)
{
	var scl = NOGX_get_pixel_ratio(); // fix for HTML5 target
	draw_set_color(c_lime);
	if(device_mouse_check_button(i, mb_left)) {
		var px = device_mouse_x_to_gui(i) * scl;
		var py = device_mouse_y_to_gui(i) * scl;
		draw_circle(px, py, 16, false);
	}
}

