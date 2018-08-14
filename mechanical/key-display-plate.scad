//
//
//
display_x_hole_spacing = 68;
display_y_hole_spacing = 45;
display_corner_radius = 6;
display_hole_diameter = 3.4;

keypad_x_hole_spacing = 55;
keypad_y_hole_spacing = 45;
keypad_corner_radius = 4;
keypad_hole_diameter = 3.4;

board_spacing = 4;

module keypad()
{
    translate([+keypad_x_hole_spacing/2, +keypad_y_hole_spacing/2]) circle(d=keypad_hole_diameter, $fn=24);
    translate([-keypad_x_hole_spacing/2, +keypad_y_hole_spacing/2]) circle(d=keypad_hole_diameter, $fn=24);
    translate([+keypad_x_hole_spacing/2, -keypad_y_hole_spacing/2]) circle(d=keypad_hole_diameter, $fn=24);
    translate([-keypad_x_hole_spacing/2, -keypad_y_hole_spacing/2]) circle(d=keypad_hole_diameter, $fn=24);

    %translate([+keypad_x_hole_spacing/2+keypad_corner_radius, +keypad_y_hole_spacing/2+keypad_corner_radius])
         square([keypad_x_hole_spacing+2*keypad_corner_radius, keypad_y_hole_spacing+2*keypad_corner_radius]);
}

module display()
{
    translate([+display_x_hole_spacing/2, +display_y_hole_spacing/2]) circle(d=display_hole_diameter, $fn=24);
    translate([-display_x_hole_spacing/2, +display_y_hole_spacing/2]) circle(d=display_hole_diameter, $fn=24);
    translate([+display_x_hole_spacing/2, -display_y_hole_spacing/2]) circle(d=display_hole_diameter, $fn=24);
    translate([-display_x_hole_spacing/2, -display_y_hole_spacing/2]) circle(d=display_hole_diameter, $fn=24);

    %translate([+display_x_hole_spacing/2+display_corner_radius, +display_y_hole_spacing/2+display_corner_radius])
         square([display_x_hole_spacing+2*display_corner_radius, display_y_hole_spacing+2*display_corner_radius]);
}

display();

translate([display_x_hole_spacing+2*display_corner_radius+board_spacing, 0]) keypad();
