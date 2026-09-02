-- ============================================================
-- CLEANING: DEPARTMENTS TABLE
-- Input cleaned data into new table clean.Departments
-- ============================================================

SELECT
	-- Convert DepartmentID to interger
	CAST(DepartmentID AS INT) AS DepartmentID,

	-- Remove leading/trailing spaces in DepartmentName
	TRIM(UPPER(DepartmentName)) AS DepartmentName,

	-- Remove leading/trailing spaces in Location
	TRIM(UPPER(Location)) AS Location

-- Insert into new table
INTO clean.Departments

FROM raw.Departments

-- Sort by Department ascending
ORDER BY CAST(DepartmentID AS INT) ASC;

