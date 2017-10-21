/******************************************************************************
 * Project enclosure
 */

include <../BH-Lib/all.scad>;

module box(
		dim,
		corners = 2, // XY corner fillet radius
		top = 2, // top edge fillet radius
		bottom = 1, // bottom edge fillet radius
		seam_overlap = 2,
		seam_z = 2,
		tolerance = 0.25,
		walls = 1.5,

		screws = true,
		screw_cs_style = "bevel", // countersink style [bevel | none | recess]
		screw_dim = SCREW_M2_DIM,
		screw_inset = [0, 0],
		screw_seam_z = 4,
		screw_surround = 1.5,
		screws_support = true// attach to box sides

	) {

	x = dim[1] > dim[0] ? dim[1] : dim[0];
	y = dim[1] > dim[0] ? dim[0] : dim[1];
	z = dim[2];

	screw_cs_dim = [screw_dim[1] + tolerance * 2, screw_dim[2] + tolerance];
	screw_r_top = screw_dim[0] / 2;
	screw_r_bot = screw_r_top + tolerance;
	screw_inset_x = screw_inset[0] ?
		max(walls + screw_surround + max(screw_r_top, screw_r_bot), screw_inset[0]) :
		max(corners, walls + screw_surround + max(screw_r_top, screw_r_bot));
	screw_inset_y = screw_inset[1] ?
		max(walls + screw_surround + max(screw_r_top, screw_r_bot), screw_inset[1]) :
		walls + screw_surround + max(screw_r_top, screw_r_bot);

	module bottom() {
		difference() {
			union() {
				difference() {

					box();

					// remove top half
					translate([0, 0, seam_z])
					cube([dim[0] * 2, dim[1] * 2, dim[2]], true);
				}
				difference() {

					box(walls / 2  + tolerance, walls / 2 - tolerance / 2);

					// remove top half (leaving gap between inner seams)
					translate([0, 0, seam_z + seam_overlap - tolerance / 2])
					cube([dim[0] * 2, dim[1] * 2, dim[2]], true);
				}
				if (screws) {
					difference() {

						// screw surrounds
						intersection() {
							box(inner = true);
							screw_surrounds(screw_r_bot);
						}

						// remove top half
						translate([0, 0, screw_seam_z - tolerance / 2])
						cube([dim[0] * 2, dim[1] * 2, dim[2]], true);
					}
				}
			}

			// screw holes
			if (screws) {
				screw_diffs(screw_r_bot);//, mock = true);
			}
		}
	}

	module box_solid(coords, corners, top, bottom) {

		module corner() {
			rounded_cylinder(h = coords[2], r = corners, f1 = bottom, f2 = top);
		}

		translate([-coords[0] / 2, -coords[1] / 2])
		hull() {
			translate([corners, corners, 0]) corner();
			translate([corners, coords[1] - corners, 0]) corner();
			translate([coords[0] - corners, coords[1] - corners, 0]) corner();
			translate([coords[0] - corners, corners, 0]) corner();
		}
	}

	module box(inset_xy = 0, walls = walls, inner = false, outer = false) {

		module inside() {
			box_solid([
					x - (inset_xy * 2 + walls * 2),
					y - (inset_xy * 2 + walls * 2),
					z - walls * 2
				],
				corners - (inset_xy + walls),
				top - walls,
				bottom - walls
			);
		}

		module outside() {
			box_solid([
					x - inset_xy * 2,
					y - inset_xy * 2,
					z,
				], corners - inset_xy, top, bottom);
		}

		// inside volume only
		if (inner) {
			inside();

		// outside volume only
		} else if (outer) {
			 outside();

		// shell
		} else {
			difference() {
				outside();
				inside();
			}
		}
	}

	// top
	module top() {
		difference() {
			union() {
				difference() {

					box();

					// remove bottom half
					translate([0, 0, -z + seam_z + seam_overlap + tolerance / 2])
					cube([dim[0] * 2, dim[1] * 2, dim[2]], true);
				}
				difference() {

					box(walls = walls / 2 - tolerance / 2);

					// remove bottom half
					translate([0, 0, -z + seam_z])
					cube([dim[0] * 2, dim[1] * 2, dim[2]], true);
				}
				if (screws) {
					difference() {

						// screw surrounds
						intersection() {
							box(inner = true);
							screw_surrounds(screw_r_top);
						}

						// remove bottom half
						translate([0, 0, -z + screw_seam_z + tolerance / 2])
						cube([dim[0] * 2, dim[1] * 2, dim[2]], true);
					}
				}
			}

			// screw holes
			if (screws) {

				// prevent from going right through
				intersection() {
					box(inner = true);
					screw_diffs(screw_r_top);
				}
			}
		}
	}

	// screw holes
	module screw_diffs(r, mock = false) {

		module diff() {
			translate([0, 0, screw_dim[2] + tolerance])
			screw_diff(dim = [r * 2, screw_dim[1], screw_dim[2]], h = z - walls, cs_style = screw_cs_style, mock = mock, tolerance = tolerance);
		}

		translate([-x / 2, -y / 2, -z / 2]) {
			translate([screw_inset_x, screw_inset_y, 0])
			diff();

			translate([screw_inset_x, y - screw_inset_y, 0])
			diff();

			translate([x - screw_inset_x, y - screw_inset_y, 0])
			diff();

			translate([x - screw_inset_x, screw_inset_y, 0])
			diff();
		}
	}

	// screw hole walls
	module screw_surrounds(r) {

		face_x = screw_inset_y > screw_inset_x;

		module surround() {
			// TODO: remove extra attach portion at seam
			screw_surround(
				attach = false,
				cs_dim = screw_cs_dim,
				h = z,
				inset = screw_inset_y,
				r = r,
				walls = screw_surround
				);
		}

		translate([-x / 2, -y / 2, -z / 2]) {
			translate([screw_inset_x, screw_inset_y, 0])
			rotate([0, 0, face_x ? -90 : 0])
			surround();

			translate([screw_inset_x, y - screw_inset_y, 0])
			rotate([0, 0, face_x ? 90 : 0])
			rotate([0, 0, 180])
			surround();

			translate([x - screw_inset_x, y - screw_inset_y, 0])
			rotate([0, 0, face_x ? -90 : 0])
			rotate([0, 0, 180])
			surround();

			translate([x - screw_inset_x, screw_inset_y, 0])
			rotate([0, 0, face_x ? 90 : 0])
			surround();
		}
	}

	translate([0, -(y / 2 + 5), z / 2])
	bottom();

	translate([0, y / 2 + 5, z / 2])
	rotate([180, 0])
	top();
}

box(
	dim = [80, 40, 20],
	corners = 5,
	top = 2,
	bottom = 10,
	seam_z = 5
);

translate([80, 0])
box(
	dim = [60, 60, 15],
	corners = 30,
	top = 10,
	bottom = 2,
	screw_cs_style = "recess",
	screw_inset_x = 0,
	screw_inset_y = 10,
	screws_support = false,
	seam_overlap = 1,
	seam_z = 3
);
