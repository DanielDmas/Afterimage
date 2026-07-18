## File I/O for GameStateStore saves: JSON, gzip-compressed
## (tech_guidelines.md D8/§5.3 — "JSON + gzip, human-diffable when
## decompressed"). Uses PackedByteArray.compress()/decompress() with
## FileAccess.COMPRESSION_GZIP, which produces a standard RFC 1952 gzip
## byte stream — so a save file this writes is a genuine standalone .gz
## file, openable with any external `gunzip`/`zcat`, not a Godot-specific
## wrapper format. Decompression reads the required output-size hint from
## the stream's own trailing ISIZE field (RFC 1952 §2.3.1: the last 4
## bytes of a gzip stream are the uncompressed size mod 2^32, little-
## endian) rather than a custom header we'd have to maintain ourselves.
class_name SaveSystem
extends RefCounted

const COMPRESSION_MODE: int = FileAccess.COMPRESSION_GZIP


## Serializes a store to canonical JSON and writes it gzip-compressed to
## `path`. Returns OK, or the FileAccess error code on failure.
static func save_store_to_path(store: GameStateStore, path: String) -> Error:
	var json_text: String = JSON.stringify(store.to_dict())
	var raw_bytes: PackedByteArray = json_text.to_utf8_buffer()
	var compressed: PackedByteArray = raw_bytes.compress(COMPRESSION_MODE)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_buffer(compressed)
	file.close()
	return OK


## Reads and decompresses a save file into a plain Dictionary (NOT yet
## migrated — callers that want a ready-to-use store should go through
## load_into_store(), which also runs the migration ladder). Returns an
## empty Dictionary if the file doesn't exist or can't be read/parsed as a
## JSON object; a missing/corrupt save is a caller-level decision, not
## something this layer throws on (ux_charter.md §3: "a corrupted save is
## quarantined, not overwritten" — the caller is what implements that).
static func load_dict_from_path(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var compressed: PackedByteArray = file.get_buffer(file.get_length())
	file.close()
	if compressed.size() < 4:
		return {}
	var uncompressed_size: int = _read_gzip_isize(compressed)
	var raw_bytes: PackedByteArray = compressed.decompress(uncompressed_size, COMPRESSION_MODE)
	var json_text: String = raw_bytes.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(json_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


## Loads a save file into `store`, running the migration ladder first.
## Returns true on success; leaves `store` untouched (does not reset it)
## if the file is missing, empty, or unreadable.
static func load_into_store(store: GameStateStore, path: String) -> bool:
	var data: Dictionary = load_dict_from_path(path)
	if data.is_empty():
		return false
	store.load_from_dict(data)
	return true


static func _read_gzip_isize(compressed: PackedByteArray) -> int:
	var n: int = compressed.size()
	return (
		compressed[n - 4]
		| (compressed[n - 3] << 8)
		| (compressed[n - 2] << 16)
		| (compressed[n - 1] << 24)
	)
