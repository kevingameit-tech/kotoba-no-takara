extends GutTest

func test_initial_stats():
	var tracker = PlayerStatsTracker.new()
	assert_eq(tracker.total_answers, 0)
	assert_eq(tracker.correct_answers, 0)
	assert_eq(tracker.get_accuracy_percentage(), 0.0)
	tracker.free()

func test_recording_answers_and_streak():
	var tracker = PlayerStatsTracker.new()
	
	tracker.record_answer(true) # Corect, streak 1
	tracker.record_answer(true) # Corect, streak 2
	tracker.record_answer(false) # Greșit, streak se resetează
	tracker.record_answer(true) # Corect, streak 1 din nou
	
	assert_eq(tracker.total_answers, 4)
	assert_eq(tracker.correct_answers, 3)
	assert_eq(tracker.current_streak, 1)
	assert_eq(tracker.best_streak, 2, "Cel mai bun streak ar trebui să fie 2.")
	assert_almost_eq(tracker.get_accuracy_percentage(), 75.0, 0.001, "Acuratețea ar trebui să fie 75%.")
	
	tracker.free()
