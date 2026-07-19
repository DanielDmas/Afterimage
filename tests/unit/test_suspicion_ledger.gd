extends AfterimageTestCase


func test_empty_ledger_totals_zero() -> void:
	var ledger := SuspicionLedger.new()
	assert_eq(ledger.total(100), 0)


func test_total_sums_multiple_undecayed_entries() -> void:
	var ledger := SuspicionLedger.new()
	ledger.add_entry("seen_grounding", SuspicionLedger.WEIGHT_SEEN_GROUNDING, 10)
	ledger.add_entry("police_pattern_behavior", SuspicionLedger.WEIGHT_POLICE_PATTERN_BEHAVIOR, 10)
	# same day added, no time elapsed -> no decay
	assert_eq(ledger.total(10), 2 + 4)


func test_entry_decays_by_one_per_week_elapsed() -> void:
	var ledger := SuspicionLedger.new()
	# weight 6
	ledger.add_entry("implausible_survival", SuspicionLedger.WEIGHT_IMPLAUSIBLE_SURVIVAL, 0)
	assert_eq(ledger.total(0), 6)
	assert_eq(ledger.total(6), 6)  # not yet a full week
	assert_eq(ledger.total(7), 5)  # exactly one week -> -1
	assert_eq(ledger.total(13), 5)  # still within the second week
	assert_eq(ledger.total(14), 4)  # two full weeks -> -2
	assert_eq(ledger.total(35), 1)  # five weeks -> 6 - 5 = 1, not yet fully decayed
	assert_eq(ledger.total(42), 0)  # six weeks -> decayed to exactly 0
	assert_eq(ledger.total(100), 0)  # stays at 0, never goes negative


func test_entry_with_future_day_added_does_not_count_yet() -> void:
	var ledger := SuspicionLedger.new()
	ledger.add_entry("gossip_of:seen_grounding", 2, 20)  # arrives on day 20
	assert_eq(ledger.total(19), 0)
	assert_eq(ledger.total(20), 2)


func test_entries_returns_a_copy_not_a_live_reference() -> void:
	var ledger := SuspicionLedger.new()
	ledger.add_entry("seen_grounding", 2, 0)
	var entries_copy: Array = ledger.entries()
	entries_copy.clear()
	assert_eq(ledger.entries().size(), 1)
