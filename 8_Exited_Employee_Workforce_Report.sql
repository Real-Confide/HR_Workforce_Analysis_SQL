--============================================================
-- REPORT 2: EXITED EMPLOYEE  REPORT
--
-- Purpose:
-- Provide a profile of employees who have left the company,
-- including their employment details, exit information,
-- tenure at exit, working hours, overtime, training and
-- latest performance rating.
--
-- Business use:
-- Helps HR understand employee exits and identify patterns
-- in tenure, exit mode, workload, training and performance.
--============================================================

CREATE VIEW report.Exited_Employee_Report AS

--============================================================
-- STEP 1: CALCULATE TENURE AT EXIT
-- Calculate the length of time each employee remained with
-- the company using their HireDate and ExitDate.
--============================================================

WITH Tenure AS (
SELECT 
	EmployeeID,
	EmployeeName,
	CASE
		WHEN ExitDate IS NOT NULL THEN DATEDIFF(year, HireDate, ExitDate)
		ELSE DATEDIFF(year, HireDate, GETDATE())
	END AS EmployeeTenure
FROM clean.Employees )

--============================================================
-- STEP 2: SUM WORKING HOURS
-- Aggregate attendance records to employee level to obtain
-- total hours worked, total overtime and average hours worked.
--============================================================

, WorkHours AS (
SELECT
	EmployeeID,
	SUM(HoursWorked) AS TotalHoursWorked,
	SUM(OvertimeHours) AS TotalOTWorked,
	ROUND(AVG(HoursWorked), 2) AS AverageHoursWorked
FROM clean.Attendance 
GROUP BY EmployeeID )

--============================================================
-- STEP 3: SUM TRAINING AND IDENTIFY LATEST PERFORMANCE
-- Employees may have multiple performance reviews.
-- SUM() calculates total training received across reviews.
-- ROW_NUMBER() identifies the employee's most recent review,
-- allowing the latest performance rating to be reported.
--============================================================

, PerformanceSummary AS (
SELECT
    p.EmployeeID,
    ROUND(SUM(p.TrainingHours), 2) AS TotalTrainingHours,
    MAX(CASE WHEN t.RatingRank = 1 THEN t.PerformanceRating END) AS LatestPerformanceRating
FROM clean.PerformanceReviews AS p
LEFT JOIN (
    SELECT	
        EmployeeID,
        ReviewDate,
        PerformanceRating,
        ROW_NUMBER() OVER(PARTITION BY EmployeeID ORDER BY ReviewDate DESC) AS RatingRank
    FROM clean.PerformanceReviews
) t ON p.EmployeeID = t.EmployeeID
GROUP BY p.EmployeeID )

--============================================================
-- STEP 4: BUILD THE EXITED EMPLOYEE REPORT
-- Combine employee information with tenure, working hours,
-- training and latest performance information.
--
-- Only employees with an EXITED employment status are
-- included in the final report.
--============================================================

SELECT
	e.EmployeeID,
	e.EmployeeName,
	COALESCE(e.Gender, 'N/A') AS Gender,
	e.Department,
	e.JobRole,
	e.Location,
	e.EmploymentType,
	e.HireDate,
	e.ExitDate,
	COALESCE(e.ExitMode, 'N/A') AS ExitMode,
	t.EmployeeTenure AS TenureAtExit,
	e.Salary,
	p.LatestPerformanceRating,
	w.TotalHoursWorked,
	w.TotalOTWorked,
	w.AverageHoursWorked,
	p.TotalTrainingHours

FROM clean.Employees AS e

LEFT JOIN Tenure AS t
ON e.EmployeeID = t.EmployeeID

LEFT JOIN WorkHours AS w
ON e.EmployeeID = w.EmployeeID

LEFT JOIN PerformanceSummary AS p
ON e.EmployeeID = p.EmployeeID

-- filter exited employee only

WHERE EmploymentStatus = 'EXITED';
