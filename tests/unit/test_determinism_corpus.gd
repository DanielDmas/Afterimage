extends AfterimageTestCase

## Exercises the determinism-corpus mechanism (tech_guidelines.md §3, §9)
## against fixtures in tests/corpus/, using StubSim (tests/fixtures/) as an
## explicitly disposable placeholder for TruthSim (Pass 3+). What this
## proves right now is narrower than the full roadmap.md M0 acceptance
## criterion ("re-simulates hash-identical on Linux/Win/mac in CI"): it
## proves the recording -> replay -> hash -> compare pipeline correctly
## detects both agreement and divergence, in-process. Cross-platform
## byte-for-byte agreement needs multi-OS CI runners, tracked separately
## in roadmap.md (still open there as of Pass 2).

const CORPUS_DIR: String = "res://tests/corpus/"
const FIXTURE_NAMES: Array[String] = ["run_001.json", "run_002.json", "run_003.json"]


func _load_fixture(file_name: String) -> ReplayLog:
	var path: String = CORPUS_DIR.path_join(file_name)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	assert_not_null(file, "corpus fixture must exist: %s" % path)
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	assert_eq(
		typeof(parsed), TYPE_DICTIONARY, "corpus fixture must parse as a JSON object: %s" % path
	)
	return ReplayLog.from_dict(parsed)


func test_all_three_fixtures_load_with_expected_frame_counts() -> void:
	assert_eq(_load_fixture("run_001.json").frame_count(), 5)
	assert_eq(_load_fixture("run_002.json").frame_count(), 8)
	assert_eq(_load_fixture("run_003.json").frame_count(), 12)


func test_replaying_a_fixture_twice_produces_identical_digests() -> void:
	for file_name: String in FIXTURE_NAMES:
		var first_run: ReplayLog = _load_fixture(file_name)
		var second_run: ReplayLog = _load_fixture(file_name)
		var digest_a: String = StubSim.run_and_digest(first_run)
		var digest_b: String = StubSim.run_and_digest(second_run)
		assert_eq(digest_a, digest_b, "%s must re-simulate hash-identical" % file_name)


func test_distinct_fixtures_produce_distinct_digests() -> void:
	# Not a tautology: this fails if the digest function is accidentally
	# insensitive to the replay content (e.g. a bug that only hashes the
	# frame count, or ignores run_seed).
	var digests: Array[String] = []
	for file_name: String in FIXTURE_NAMES:
		digests.append(StubSim.run_and_digest(_load_fixture(file_name)))
	assert_eq(digests.size(), 3)
	assert_ne(digests[0], digests[1])
	assert_ne(digests[1], digests[2])
	assert_ne(digests[0], digests[2])


func test_digest_is_sensitive_to_run_seed() -> void:
	var a := ReplayLog.new(1, "fixture")
	a.record(InputFrame.new(1, {"move_x": 1}))
	var b := ReplayLog.new(2, "fixture")
	b.record(InputFrame.new(1, {"move_x": 1}))
	assert_ne(StubSim.run_and_digest(a), StubSim.run_and_digest(b))


func test_digest_is_sensitive_to_an_extra_frame() -> void:
	# This is the "intentionally seeded divergence" roadmap.md asks the
	# determinism CI job to catch: an extra/changed tick in an otherwise
	# identical run must change the digest.
	var shorter := ReplayLog.new(5, "fixture")
	shorter.record(InputFrame.new(1, {"move_x": 1}))
	shorter.record(InputFrame.new(2, {"move_x": 1}))

	var longer := ReplayLog.new(5, "fixture")
	longer.record(InputFrame.new(1, {"move_x": 1}))
	longer.record(InputFrame.new(2, {"move_x": 1}))
	longer.record(InputFrame.new(3, {"move_x": 1}))

	assert_ne(StubSim.run_and_digest(shorter), StubSim.run_and_digest(longer))


func test_digest_is_a_sha256_hex_string() -> void:
	var replay := ReplayLog.new(1, "fixture")
	var digest: String = StubSim.run_and_digest(replay)
	assert_eq(digest.length(), 64, "SHA-256 hex digest must be 64 characters")
	for c: String in digest:
		assert_true(c in "0123456789abcdef", "digest must be lowercase hex, got char '%s'" % c)
