## art_direction.md §5's ten palette anchors ("hex, for consistency across
## artists... the full ramps are derived from these ten and live with the
## tileset sources"). A future real Godot `Theme` resource (built in an
## actual editor session — hand-authoring a `.tres` Theme file blind, with
## no Godot editor or renderer available in this sandbox to verify it,
## would be exactly the kind of untested-in-this-sandbox risk this
## codebase has avoided since Pass 6's static-typing gotcha and Pass 9's
## RefCounted instance-id gotcha) will source its colors from these named
## constants, not the reverse — this file is the single place the ten hex
## values are spelled out, so a future Theme never duplicates them.
class_name ThemePalette
extends RefCounted

const CARBON_PAPER: String = "#E8E0CE"
const FOLDER_OCHRE: String = "#C9A96A"
const MUNICIPAL_GREEN: String = "#7A8B6F"
const SODIUM_ORANGE: String = "#E89440"
const NIGHT_BASE: String = "#1A1E2A"
const FLUORESCENT_WHITE: String = "#DDE8DC"
const CLUB_TEAL: String = "#3FB8AF"
const BLOOD: String = "#7E2D26"
const ELISKA_BLUE_GREY: String = "#8C9BAB"
const RADEK_LEATHER_BROWN: String = "#6B4A38"

const ALL_ANCHORS: Dictionary = {
	"carbon_paper": CARBON_PAPER,
	"folder_ochre": FOLDER_OCHRE,
	"municipal_green": MUNICIPAL_GREEN,
	"sodium_orange": SODIUM_ORANGE,
	"night_base": NIGHT_BASE,
	"fluorescent_white": FLUORESCENT_WHITE,
	"club_teal": CLUB_TEAL,
	"blood": BLOOD,
	"eliska_blue_grey": ELISKA_BLUE_GREY,
	"radek_leather_brown": RADEK_LEATHER_BROWN,
}


static func color(hex: String) -> Color:
	return Color(hex)


static func anchor_names() -> Array:
	var names: Array = ALL_ANCHORS.keys()
	names.sort()
	return names
