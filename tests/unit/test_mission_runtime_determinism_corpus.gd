extends AfterimageTestCase

## The Phase B acceptance item docs/forward_dev_plan.md's own text left open
## after MissionRuntime shipped: "a determinism-corpus fixture for a full
## MissionRuntime-driven run... no hand-computed 'golden' value, just
## 'replays identically given the same seed'." This is that fixture —
## MissionRuntimeDigest (tests/fixtures/) re-simulates the *entire* live
## pipeline (TruthSim + MissionRuntime + DistortionDirector +
## MindModelEventBridge), not just the truth layer test_determinism_corpus.gd
## already covers.
##
## Reuses the same three corpus fixtures under tests/corpus/ rather than
## authoring new ones: they're pure recorded InputFrame streams, agnostic to
## which digest function processes them, and run_003.json's full
## Ground-hold-to-completion cycle is exactly the scenario that exercises
## MissionRuntime's ground-resolution branch (every active op cleared,
## Director notified) for real.

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


func test_replaying_a_fixture_twice_produces_identical_digests() -> void:
	for file_name: String in FIXTURE_NAMES:
		var first_run: ReplayLog = _load_fixture(file_name)
		var second_run: ReplayLog = _load_fixture(file_name)
		var digest_a: String = MissionRuntimeDigest.run_and_digest(first_run)
		var digest_b: String = MissionRuntimeDigest.run_and_digest(second_run)
		assert_eq(
			digest_a,
			digest_b,
			(
				"%s must re-simulate hash-identical through the full MissionRuntime pipeline"
				% file_name
			)
		)


func test_distinct_fixtures_produce_distinct_digests() -> void:
	# Not a tautology: this fails if the digest function is accidentally
	# insensitive to the replay content (e.g. only hashes the frame count).
	var digests: Array[String] = []
	for file_name: String in FIXTURE_NAMES:
		digests.append(MissionRuntimeDigest.run_and_digest(_load_fixture(file_name)))
	assert_eq(digests.size(), 3)
	assert_ne(digests[0], digests[1])
	assert_ne(digests[1], digests[2])
	assert_ne(digests[0], digests[2])


## run_seed doubles as MissionRuntime's Director seed (mission_runtime_digest.gd's
## own class doc) — this proves the digest is actually sensitive to that
## reuse, not just to the frames, by replaying the identical frame stream
## under two different seeds.
func test_digest_is_sensitive_to_the_director_seed() -> void:
	var a := ReplayLog.new(1, "fixture")
	a.record(InputFrame.new(1, {"move_x": 1}))
	var b := ReplayLog.new(2, "fixture")
	b.record(InputFrame.new(1, {"move_x": 1}))
	assert_ne(MissionRuntimeDigest.run_and_digest(a), MissionRuntimeDigest.run_and_digest(b))


func test_digest_is_a_sha256_hex_string() -> void:
	var replay := ReplayLog.new(1, "fixture")
	var digest: String = MissionRuntimeDigest.run_and_digest(replay)
	assert_eq(digest.length(), 64, "SHA-256 hex digest must be 64 characters")
	for c: String in digest:
		assert_true(c in "0123456789abcdef", "digest must be lowercase hex, got char '%s'" % c)
