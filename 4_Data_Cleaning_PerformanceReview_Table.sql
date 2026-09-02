-- ============================================================
-- CLEANING: PERFORMANCEREVIEWS TABLE
-- Input cleaned data into new table clean.PerformanceReviews
-- ============================================================

SELECT

	-- Ensure ReviewID is stored as interger
	CAST(ReviewID AS INT) AS ReviewID,

	-- Ensure EmployeeID is stored as interger
	CAST(EmployeeID AS INT) AS EmployeeID,

	-- Convert ReviewDate to DATE while handling
    -- multiple formats found in the raw data
	COALESCE(
			TRY_CAST(ReviewDate AS DATE),
			TRY_CONVERT(DATE, ReviewDate, 103),
			TRY_CONVERT(DATE, ReviewDate, 101)
	) AS ReviewDate,

	-- Handle PerformanceRating higher than 5
	CASE	
		WHEN PerformanceRating > 5 OR PerformanceRating < 1 THEN NULL
		ELSE PerformanceRating
	END AS PerformanceRating,

	TrainingHours,

	-- Ensure ReviewerEmployeeID is stored as interger
	CAST(ReviewerEmployeeID AS INT) AS ReviewerEmployeeID

-- Insert into new table
INTO clean.PerformanceReviews

FROM raw.PerformanceReviews;