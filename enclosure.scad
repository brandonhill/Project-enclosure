/******************************************************************************
 * Project enclosure
 */

include <../BH-Lib/all.scad>;

module box(
		dim,
		r_corner = 2,
		r_top = 2,
		r_bot = 1,
		seam_overlap = 1,
		seam_z,
		walls = 1,

		screws = true,
		screw_cs_style = "none", // countersink style [bevel | none | recess]
		screw_dim = SCREW_M2_FLAT_DIM,
		screw_inset = [0, 0],
		screw_seam_z,
		screw_surround = 1.5,
		screw_supports = true, // attach to box sides
		tolerance_clear = 0.25,
		tolerance_close = 0.15,
		tolerance_fit = 0.2,
	) {

	x = dim[1] > dim[0] ? dim[1] : dim[0];
	y = dim[1] > dim[0] ? dim[0] : dim[1];

	_corner_r = max(r_bot, r_corner, r_top);
	if (max(r_bot, r_top) > r_corner)
		warn(["Corner radius (", r_corner, ") cannot be less than r_top (", r_top, ") or r_bot (", r_bot, ") radius. Adjusted to ", _corner_r]);

	_seam_z = seam_z != undef ? seam_z : dim[2] - walls - r_top;
	_screw_seam_z = screw_seam_z != undef ? screw_seam_z : _seam_z - seam_overlap;

	screw_r_top = screw_dim[0] / 2 + tolerance_clear;
	screw_r_bot = screw_dim[0] / 2;
	screw_inset_x = screw_inset[0] ?
		max(walls + screw_surround + max(screw_r_top, screw_r_bot), screw_inset[0]) :
		max(_corner_r, walls + screw_surround + max(screw_r_top, screw_r_bot));
	screw_inset_y = screw_inset[1] ?
		max(walls + screw_surround + max(screw_r_top, screw_r_bot), screw_inset[1]) :
		walls + screw_surround + max(screw_r_top, screw_r_bot);

	module bottom() {
		difference() {
			union() {

				// outer/upper seam portion
				difference() {
					solid(r_bot);
					solid(r_bot, offset = -(walls - tolerance_fit) / 2);

					// remove top half
					translate([0, 0, _seam_z])
					cube([dim[0] * 2, dim[1] * 2, dim[2]], true);
				}

				// inner/lower seam portion
				difference() {
					solid(r_bot);
					solid(r_bot, offset = -walls);

					// remove top half (leaving gap between inner seams)
					translate([0, 0, _seam_z - seam_overlap - tolerance_close / 2])
					cube([dim[0] * 2, dim[1] * 2, dim[2]], true);
				}
			}
		}

		if (screws) {
			difference() {

				// screw surrounds
				intersection() {
					solid(r_bot, offset = -walls);
					screw_surrounds(screw_r_bot);
				}

				// remove top half
				translate([0, 0, _screw_seam_z - tolerance_close / 2])
				cube([dim[0] * 2, dim[1] * 2, dim[2]], true);

				// screw holes
				if (screws) {

					// prevent from going right through
//					intersection() {
//						solid(r_bot, offset = -walls);
						screw_diffs(screw_r_bot);
//					}
				}
			}
		}
	}

	module profile(x, offset = 0) {
		hull()
		reflect(y = false)
		translate([x, 0]) {
			translate([0, -dim[2] / 2])
			if (r_bot <= 0)
				translate([offset, offset])
				translate([-0.05, 0.05])
				square(0.1, true);
			else
				translate([-r_bot, r_bot])
				circle(r_bot + offset);

			translate([0, dim[2] / 2])
			if (r_top <= 0)
				translate([offset, offset])
				translate([-0.05, -0.05])
				square(0.1, true);
			else
				translate([-r_top, -r_top])
				circle(r_top + offset);
		}
	}

	// screw holes
	module screw_diffs(r, mock = false) {

		module diff() {
			screw_diff(
				dim = [r * 2, screw_dim[1], screw_dim[2]],
				h = dim[2] - walls - tolerance_clear - screw_dim[2],
				cs_style = screw_cs_style,
				mock = mock,
				tolerance = tolerance_close);
		}

		translate([-x / 2, -y / 2, dim[2] / 2]) {
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
	module screw_surrounds() {

		face_x = screw_inset_y > screw_inset_x;

		module surround() {
			// TODO: remove extra attach portion at seam (when screw seam not default)
			screw_surround(
				attach = screw_supports,
				cs_style = screw_cs_style,
				dim = screw_dim,
				h = dim[2],
				inset = screw_inset_y,
				walls = screw_surround);
		}

		translate([-x / 2, -y / 2, dim[2] / 2])
		scale([1, 1, -1])
		{
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

	module solid(r, offset = 0, top = false) {
		hull()
		reflect()
		for (z = [-1, 1])
		translate([dim[0] / 2, dim[1] / 2, dim[2] / 2 * z])
		if (r_corner + r <= 0)
			translate([offset, offset, offset * z])
			translate([-0.05, -0.05, -0.05 * z])
			cube(0.1, true);
		else
			if (r + offset > 0 && (z < 0 ? !top : top))
				translate([-(r_corner), -(r_corner), -r * z])
				rotate_extrude(angle = 90)
				translate([r_corner - r, 0])
				rotate([0, 0, z < 0 ? -90 : 0])
				segment(90, r + offset);
			else
				translate([0, 0, offset * z])
				translate([-(r_corner), -(r_corner), -0.05 * z])
				cylinder(h = 0.1, r = r_corner + offset);
	}

	module top() {

		difference() {
			union() {
				// outer/upper seam portion
				difference() {
					solid(r_top, top = true);

					// remove bottom half
					translate([0, 0, -dim[2] + _seam_z])
					cube([dim[0] * 2, dim[1] * 2, dim[2]], true);
				}
				// inner/lower seam portion
				difference() {
					solid(r_top, offset = -(walls + tolerance_fit) / 2, top = true);

					// remove bottom half
					translate([0, 0, -dim[2] + _seam_z - seam_overlap + tolerance_close / 2])
					cube([dim[0] * 2, dim[1] * 2, dim[2]], true);
				}
			}

			solid(r_top, offset = -walls, top = true);

			if (screws)
				screw_diffs(screw_r_top);
		}

		if (screws)
		difference() {

			// screw surrounds
			intersection() {
				solid(r_top, offset = -walls, top = true);
				screw_surrounds(screw_r_top);
			}

			// remove bottom half
			translate([0, 0, -dim[2] + _screw_seam_z + tolerance_close / 2])
			cube([dim[0] * 2, dim[1] * 2, dim[2]], true);

			// screw holes
			screw_diffs(screw_r_top, mock = true);
		}
	}

	translate([0, y / 2 + 5, dim[2] / 2])
	bottom();

	translate([0, -(y / 2 + 5), dim[2] / 2])
	rotate([180, 0])
	top();
}
