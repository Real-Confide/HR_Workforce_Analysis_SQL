-- ============================================================
-- CLEANING: ATTENDANCE TABLE
-- Input cleaned data into new table clean.Attendance
-- ============================================================

SELECT

	-- Convert AttendanceID to integer
	CAST(AttendanceID AS INT) AS AttendanceID,

	-- Convert EmployeeID to integer
	CAST(EmployeeID AS INT) AS EmployeeID,

	-- Standardise AttendanceDate to DATE
    -- TRY_CAST/TRY_CONVERT prevents invalid dates from causing errors
    -- Multiple formats are attempted to handle inconsistent raw data
	COALESCE(
		TRY_CAST(AttendanceDate AS DATE),
        TRY_CONVERT(DATE, AttendanceDate, 103),
        TRY_CONVERT(DATE, AttendanceDate, 101)
    ) AS AttendanceDate, 

	-- Standardise Status by removing leading/trailing spaces
    -- and converting all values to uppercase
	TRIM(UPPER(Status)) AS Status,

	-- Standardise HoursWorked:
    -- 1. Convert negative values to positive
    -- 2. Set missing hours for ABSENT/LEAVE records to 0
    -- 3. Preserve NULL for other statuses where hours are missing
	CASE
		WHEN TRIM(UPPER(Status)) IN ('ABSENT', 'LEAVE') THEN COALESCE(ABS(HoursWorked), 0)
		ELSE ABS(HoursWorked) 
	END AS HoursWorked,

	-- Standardise OvertimeHours based on attendance status:
    -- 1. Positive overtime for non-working statuses is treated as invalid
    -- 2. PRESENT employees with missing HoursWorked have NULL overtime
    -- 3. Missing overtime for PRESENT employees is replaced with 0
    -- 4. Remaining negative overtime values are converted to positive
    -- 5. Remaining NULL overtime values are replaced with 0
	CASE
		WHEN TRIM(UPPER(Status)) NOT IN ('PRESENT', 'LATE') AND OvertimeHours > 0 THEN NULL
		WHEN TRIM(UPPER(Status)) = 'PRESENT' AND HoursWorked IS NULL THEN NULL
		WHEN TRIM(UPPER(Status)) = 'PRESENT' THEN COALESCE(ABS(OvertimeHours), 0)
		ELSE COALESCE(ABS(OvertimeHours) , 0)
END AS OvertimeHours

--Insert into new table
INTO clean.Attendance

FROM raw.Attendance;

