-- ============================================================
-- CLEANING: EMPLOYEES TABLE
-- Input cleaned data into new table clean.Employee
-- ============================================================

SELECT
	EmployeeID,

	-- Standardise employee name by removing unwanted spaces
	TRIM(EmployeeName) AS EmployeeName,

	-- Standardise gender values to uppercase
	TRIM(UPPER(Gender)) AS Gender,

	-- Ensure DepartmentID is stored as an integer
	CAST(t.DepartmentID AS INT) AS DepartmentID,
	CASE 
		WHEN TRIM(UPPER(Department)) IS NULL THEN TRIM(UPPER(d.DepartmentName))
		ELSE TRIM(UPPER(Department))
	END AS Department,

	-- Remove unwanted spaces from job role
	TRIM(JobRole) AS JobRole,

	-- Use employee location when available.
    -- If missing, retrieve it from the Departments table.
	CASE
		WHEN TRIM(UPPER(t.Location)) IS NULL THEN TRIM(UPPER(d.Location))
		ELSE TRIM(UPPER(t.Location))
	END AS Location,

	-- Standardise employment type
	TRIM(UPPER(EmploymentType)) AS EmploymentType,

	-- Convert HireDate to DATE while handling
    -- multiple formats found in the raw data
	COALESCE(
		TRY_CAST(HireDate AS DATE),
        TRY_CONVERT(DATE, HireDate, 103),
        TRY_CONVERT(DATE, HireDate, 101)
    ) AS HireDate,

	-- Treat zero salary as missing
    -- and convert salary to a decimal datatype
	CAST (NULLIF(Salary, 0) AS DECIMAL(18,0)) AS Salary,

	-- Standardise employment status
	TRIM(UPPER(EmploymentStatus)) AS EmploymentStatus,

	-- Active employees should not have an ExitDate.
    -- For other statuses, convert ExitDate to DATE.
	CASE
		WHEN TRIM(UPPER(EmploymentStatus)) = 'ACTIVE' THEN NULL
		ELSE COALESCE(
			TRY_CAST(ExitDate AS DATE),
			TRY_CONVERT(DATE, ExitDate, 103),
			TRY_CONVERT(DATE, ExitDate, 101) ) 
	END AS ExitDate,

	-- Standardise exit mode
	TRIM(UPPER(ExitMode)) AS ExitMode

-- Insert into new table
INTO clean.Employees

FROM (
		-- EmployeeID is an exact duplicate in the raw data.
		-- Assign a row number and retain one record per EmployeeID.
		SELECT 
		*,
		ROW_NUMBER() OVER(PARTITION BY EmployeeID ORDER BY EmployeeID) AS IDRank
		FROM raw.Employees
) t

-- Use the Departments table as a reference
-- for missing department and location values.
LEFT JOIN raw.Departments AS d
ON t.DepartmentID = d.DepartmentID

--Keep only uniuqe employees row
WHERE IDRank = 1;

