//
//
//
display_x_hole_spacing = 68;
display_y_hole_spacing = 40;
display_corner_radius = 6;
display_hole_diameter = 3.4;

keypad_x_hole_spacing = 55;
keypad_y_hole_spacing = 45;
keypad_corner_radius = 4;
keypad_hole_diameter = 3.4;
slot_width = 3;
slot_length = 35;

board_spacing = 4;
board_margin = 4;
board_corner_radius = 5;

module keypad(hole_diameter)
{
    translate([+keypad_x_hole_spacing/2, +keypad_y_hole_spacing/2]) circle(d=hole_diameter, $fn=24);
    translate([-keypad_x_hole_spacing/2, +keypad_y_hole_spacing/2]) circle(d=hole_diameter, $fn=24);
    translate([+keypad_x_hole_spacing/2, -keypad_y_hole_spacing/2]) circle(d=hole_diameter, $fn=24);
    translate([-keypad_x_hole_spacing/2, -keypad_y_hole_spacing/2]) circle(d=hole_diameter, $fn=24);
    
    translate([0, keypad_y_hole_spacing/2+keypad_corner_radius+slot_width/2]) hull()
    {
        translate([-slot_length/2,0]) circle(d=slot_width, $fn=24);
        translate([+slot_length/2,0]) circle(d=slot_width, $fn=24);
    }

    %square([keypad_x_hole_spacing+2*keypad_corner_radius, keypad_y_hole_spacing+2*keypad_corner_radius], center=true);
}

module display(hole_diameter)
{
    translate([+display_x_hole_spacing/2, +display_y_hole_spacing/2]) circle(d=hole_diameter, $fn=24);
    translate([-display_x_hole_spacing/2, +display_y_hole_spacing/2]) circle(d=hole_diameter, $fn=24);
    translate([+display_x_hole_spacing/2, -display_y_hole_spacing/2]) circle(d=hole_diameter, $fn=24);
    translate([-display_x_hole_spacing/2, -display_y_hole_spacing/2]) circle(d=hole_diameter, $fn=24);
    
    translate([0, display_y_hole_spacing/2+display_corner_radius+board_margin/2]) hull()
    {
        translate([-slot_length/2,0]) circle(d=slot_width, $fn=24);
        translate([+slot_length/2,0]) circle(d=slot_width, $fn=24);
    }

    %square([display_x_hole_spacing+2*display_corner_radius, display_y_hole_spacing+2*display_corner_radius], center=true);
}


module holes(outline)
{
    translate([-(display_x_hole_spacing/2+display_corner_radius+slot_width/2), 0]) display(outline);

translate([+(board_spacing/2+keypad_corner_radius+keypad_x_hole_spacing/2), 0]) keypad(outline);
}

difference()
{
hull() 
    {
      translate([-(board_margin+display_x_hole_spacing+2*display_corner_radius+board_spacing/2), +(board_margin+keypad_y_hole_spacing/2+keypad_corner_radius)]) circle(board_corner_radius, $fn=48); 
      translate([-(board_margin+display_x_hole_spacing+2*display_corner_radius+board_spacing/2), -(board_margin+keypad_y_hole_spacing/2+keypad_corner_radius)]) circle(board_corner_radius, $fn=48); 
        
      translate([+(board_margin+keypad_x_hole_spacing+2*keypad_corner_radius+board_spacing/2), +(board_margin+keypad_y_hole_spacing/2+keypad_corner_radius)]) circle(board_corner_radius, $fn=48); 
     translate([+(board_margin+keypad_x_hole_spacing+2*keypad_corner_radius+board_spacing/2), -(board_margin+keypad_y_hole_spacing/2+keypad_corner_radius)]) circle(board_corner_radius, $fn=48); 
        }
holes(keypad_hole_diameter);
}