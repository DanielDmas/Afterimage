extends AfterimageTestCase


func test_constructor_defaults_to_no_rows() -> void:
	var screen := ScreenSpec.new("Test Screen")
	assert_eq(screen.title, "Test Screen")
	assert_eq(screen.rows.size(), 0)


func test_add_row_appends_a_labeled_row() -> void:
	var screen := ScreenSpec.new("Test Screen")
	screen.add_row("Fatigue", "Murmur")
	assert_eq(screen.rows.size(), 1)
	assert_eq(screen.rows[0]["label"], "Fatigue")
	assert_eq(screen.rows[0]["value"], "Murmur")


func test_screen_reader_text_includes_title_and_every_row() -> void:
	var screen := ScreenSpec.new("Dr. Sova's Worksheets")
	screen.add_row("Acute Stress", "Quiet")
	screen.add_row("Fatigue", "Murmur")
	var text: String = screen.screen_reader_text()
	assert_true(text.begins_with("Dr. Sova's Worksheets"))
	assert_true(text.contains("Acute Stress: Quiet"))
	assert_true(text.contains("Fatigue: Murmur"))


func test_screen_reader_text_with_no_rows_is_just_the_title() -> void:
	var screen := ScreenSpec.new("Empty Screen")
	assert_eq(screen.screen_reader_text(), "Empty Screen")
