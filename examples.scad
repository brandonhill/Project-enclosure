
use <enclosure.scad>

TOLERANCE_CLOSE = 0.15;
TOLERANCE_FIT = 0.2;
TOLERANCE_CLEAR = 0.25;

// typical project enclosure style
box(
	dim = [80, 40, 20],
	r_corner = 4,
	r_bot = 4,
	r_top = 0,
	tolerance_clear = TOLERANCE_CLEAR,
	tolerance_close = TOLERANCE_CLOSE,
	tolerance_fit = TOLERANCE_FIT
);

// round box
//*
translate([80, 0])
box(
	dim = [60, 60, 15],
	r_corner = 30,
	r_top = 0,
	r_bot = 10,
	screw_cs_style = "bevel",
	screw_inset = [0, 5],
	screw_seam_z = 10,
	screw_supports = false,
	seam_z = 12,
	tolerance_clear = TOLERANCE_CLEAR,
	tolerance_close = TOLERANCE_CLOSE,
	tolerance_fit = TOLERANCE_FIT
);
