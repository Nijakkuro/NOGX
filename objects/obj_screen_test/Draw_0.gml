// window
var ww = window_get_width();
var wh = window_get_height();

// display
var dw = display_get_width();
var dh = display_get_height();

// application surface
var sw = surface_get_width(application_surface);
var sh = surface_get_height(application_surface);

// gui
var gw = display_get_gui_width();
var gh = display_get_gui_height();

// canvas
var cw = NOGX_get_canvas_width();
var ch = NOGX_get_canvas_height();

// pixel ratio
var pr = NOGX_get_pixel_ratio();

draw_sprite_stretched(spr_screen_test, 0, 0, 0, cw, ch);

draw_set_color(c_white);
draw_text(16, 16, "Hello, world!");
draw_text(16, 36, $"Window Size = {ww} x {wh}");
draw_text(16, 56, $"Browser Size = {browser_width} x {browser_height}");
draw_text(16, 76, $"Display Size = {dw} x {dh}");
draw_text(16, 96, $"Surface Size = {sw} x {sh}");
draw_text(16, 116, $"GUI Size = {gw} x {gh}");
draw_text(16, 136, $"Canvas Size = {cw} x {ch}");
draw_text(16, 156, $"Pixel Ratio = {pr}");

draw_text(16, 186, $"Use the NOGX_get_canvas_width() and NOGX_get_canvas_height() functions\nto get the actual canvas size in pixels");

