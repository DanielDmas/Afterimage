extends AfterimageTestCase

const TEST_SAVE_PATH: String = "user://test_save_system_tmp.sav"
const MISSING_PATH: String = "user://this_file_should_never_exist_afterimages.sav"


func after_each() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)


func test_save_and_load_round_trip_preserves_state() -> void:
	var store := GameStateStore.new()
	store.set_value(["campaign", "day"], 11)
	store.set_value(["campaign", "flags", "x"], true)

	var err: Error = SaveSystem.save_store_to_path(store, TEST_SAVE_PATH)
	assert_eq(err, OK)
	assert_true(FileAccess.file_exists(TEST_SAVE_PATH))

	var loaded := GameStateStore.new()
	var ok: bool = SaveSystem.load_into_store(loaded, TEST_SAVE_PATH)
	assert_true(ok)
	assert_eq(loaded.to_dict(), store.to_dict())


## save -> load -> save again must produce byte-identical files (roadmap.md
## M0's explicit acceptance criterion): proves to_dict()'s key order and
## JSON.stringify() are stable across a round trip, not just that the
## Dictionary content matches.
func test_save_load_save_is_byte_identical() -> void:
	var store := GameStateStore.new()
	store.set_value(["campaign", "day"], 8)
	store.set_value(["campaign", "flags", "a"], true)
	store.set_value(["campaign", "flags", "b"], false)

	assert_eq(SaveSystem.save_store_to_path(store, TEST_SAVE_PATH), OK)
	var first_bytes: PackedByteArray = FileAccess.get_file_as_bytes(TEST_SAVE_PATH)

	var reloaded := GameStateStore.new()
	assert_true(SaveSystem.load_into_store(reloaded, TEST_SAVE_PATH))
	assert_eq(SaveSystem.save_store_to_path(reloaded, TEST_SAVE_PATH), OK)
	var second_bytes: PackedByteArray = FileAccess.get_file_as_bytes(TEST_SAVE_PATH)

	assert_eq(first_bytes, second_bytes, "save -> load -> save must be byte-identical")


func test_save_produces_a_valid_gzip_stream() -> void:
	var store := GameStateStore.new()
	assert_eq(SaveSystem.save_store_to_path(store, TEST_SAVE_PATH), OK)
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(TEST_SAVE_PATH)
	# RFC 1952 §2.3.1: every gzip stream starts with magic bytes 0x1F 0x8B.
	assert_gte(bytes.size(), 2)
	assert_eq(bytes[0], 0x1F, "gzip magic byte 1")
	assert_eq(bytes[1], 0x8B, "gzip magic byte 2")


func test_load_dict_from_nonexistent_path_returns_empty() -> void:
	assert_eq(SaveSystem.load_dict_from_path(MISSING_PATH), {})


func test_load_into_store_returns_false_when_missing() -> void:
	var store := GameStateStore.new()
	assert_false(SaveSystem.load_into_store(store, MISSING_PATH))


## Writes a v1-shaped save by hand (a GameStateStore never holds an old
## schema in memory, so this bypasses it deliberately) and confirms
## SaveSystem migrates it on load — save format and migration ladder
## exercised together, end to end.
func test_load_into_store_migrates_old_saves() -> void:
	var v1_json: String = JSON.stringify({"schema_version": 1, "day": 6, "flags": {}})
	var compressed: PackedByteArray = v1_json.to_utf8_buffer().compress(SaveSystem.COMPRESSION_MODE)
	var file: FileAccess = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_buffer(compressed)
	file.close()

	var store := GameStateStore.new()
	assert_true(SaveSystem.load_into_store(store, TEST_SAVE_PATH))
	assert_eq(store.get_value(["schema_version"]), 2)
	assert_eq(store.get_value(["campaign", "day"]), 6)
