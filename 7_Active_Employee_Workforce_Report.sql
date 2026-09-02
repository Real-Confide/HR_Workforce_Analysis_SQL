--============================================================
-- REPORT 1: ACTIVE EMPLOYEE WORKFORCE REPORT
-- Purpose:
-- Create a reusable employee-level report containing
-- workforce details, tenure, working hours, training,
-- latest performance review and reviewer information.
--============================================================

CREATE VIEW report.Active_Employee_Workforce_Report AS 

--============================================================
-- STEP 1: CALCULATE EMPLOYEE TENURE
-- For active employees, calculate tenure from HireDate
-- to the current date.
-- For exited employees, calculate tenure from HireDate
-- to ExitDate.
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
-- STEP 2: SUM EMPLOYEE WORKING HOURS
-- Aggregate attendance records to employee level so that
-- each employee has one total for:
--   - Total hours worked
--   - Total overtime hours
--   - Average hours worked
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
-- STEP 3: SUM TRAINING AND IDENTIFY LATEST REVIEW
-- PerformanceReviews can contain multiple records per employee.
-- Therefore:
--   - SUM() gives total training hours across all reviews.
--   - ROW_NUMBER() identifies the employee's most recent review.
--   - The latest review date and rating are then returned.
--============================================================

, PerformanceSummary AS (
SELECT
    p.EmployeeID,
    ROUND(SUM(p.TrainingHours), 2) AS TotalTrainingHours,
    MAX(t.ReviewDate) AS LatestReviewDate,
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
-- STEP 4: IDENTIFY THE REVIEWER FROM THE LATEST REVIEW
-- Each employee may have multiple performance reviews and
-- potentially different reviewers.
--
-- ROW_NUMBER() ranks reviews from newest to oldest.
-- We keep only Rank = 1 so that each employee has ONE reviewer.
--
-- ReviewerEmployeeID is then matched to Employees.EmployeeID
-- to retrieve the reviewer's name.
--============================================================

, ReviewerInfo AS (
SELECT
	EmployeeID,
	ReviewerID,
	ReviewerName
FROM (
SELECT 
	p.EmployeeID,
	p.ReviewerEmployeeID AS ReviewerID,
	ROW_NUMBER() OVER(PARTITION BY p.EmployeeID ORDER BY ReviewDate DESC) AS ReviewerRank,
	e.EmployeeName AS ReviewerName
FROM clean.PerformanceReviews AS p
LEFT JOIN clean.Employees AS e
ON e.EmployeeID = p.ReviewerEmployeeID) t
WHERE ReviewerRank = 1 )

--============================================================
-- STEP 5: BUILD THE FINAL EMPLOYEE REPORT
-- Start with Employees because the report is employee-level.
--
-- Each CTE is joined back using EmployeeID to bring the
-- calculated information into one report.
--============================================================

SELECT
	e.EmployeeID,
	e.EmployeeName,
	COALESCE(e.Gender, 'N/A') AS Gender,
	e.Department,
	e.JobRole,
	e.Location,
	e.EmploymentType,
	e.Salary,
	e.Salary * 12 AS AnnualSalary,
	e.HireDate,
	t.EmployeeTenure,
	w.TotalHoursWorked,
	w.TotalOTWorked,
	w.AverageHoursWorked,
	p.TotalTrainingHours,
	p.LatestReviewDate,
	p.LatestPerformanceRating,
	r.ReviewerID,
	COALESCE(r.ReviewerName, 'N/A') AS ReviewerName

FROM clean.Employees AS e

LEFT JOIN Tenure AS t
ON e.EmployeeID = t.EmployeeID

LEFT JOIN WorkHours AS w
ON e.EmployeeID = w.EmployeeID

LEFT JOIN PerformanceSummary AS p
ON e.EmployeeID = p.EmployeeID

LEFT JOIN ReviewerInfo AS r
ON r.EmployeeID =  e.EmployeeID 

-- Filter active employee only

WHERE EmploymentStatus = 'ACTIVE';
