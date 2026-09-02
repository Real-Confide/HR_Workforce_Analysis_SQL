-- =======================================================
-- Workforce composition
-- =======================================================

-- Q1. What does the current workforce look like?
-- By department
WITH DepartmentEmployeeCount AS (
SELECT
	DepartmentID,
	Department,
	COUNT(EmployeeID) AS EmployeeCount
FROM clean.Employees
GROUP BY 
	DepartmentID,
	Department )
SELECT 
	Department,
	EmployeeCount,
	CONCAT(CAST(EmployeeCount AS FLOAT) / SUM(EmployeeCount) OVER() * 100, '%') AS PercentageOfWorkforce
FROM DepartmentEmployeeCount
ORDER BY EmployeeCount DESC;

-- By employment type
WITH EmploymentTypeCount AS (
SELECT
	EmploymentType,
	COUNT(EmployeeID) AS EmployeeCount
FROM clean.Employees
GROUP BY 
	EmploymentType )
SELECT 
	EmploymentType,
	EmployeeCount,
	CONCAT(CAST(EmployeeCount AS FLOAT) / SUM(EmployeeCount) OVER() * 100, '%') AS PercentageOfWorkforce
FROM EmploymentTypeCount
ORDER BY EmployeeCount DESC;

-- Q2. What is the distribution of employees by gender
WITH GenderCount AS (
SELECT
	Gender,
	COUNT(EmployeeID) AS EmployeeCount
FROM clean.Employees
GROUP BY 
	Gender )
SELECT 
	CASE
		WHEN Gender IS NULL THEN 'N/A'
		ELSE Gender
	END AS Gender,
	EmployeeCount,
	CONCAT(CAST(EmployeeCount AS FLOAT) / SUM(EmployeeCount) OVER() * 100, '%') AS PercentageOfWorkforce
FROM GenderCount
ORDER BY EmployeeCount DESC;

-- Q3. Which locations have the largest workforce?
WITH LocationEmployeeCount AS (
SELECT
	Location,
	COUNT(EmployeeID) AS EmployeeCount
FROM clean.Employees
GROUP BY 
	Location )
SELECT 
	Location,
	EmployeeCount,
	CONCAT(CAST(EmployeeCount AS FLOAT) / SUM(EmployeeCount) OVER() * 100, '%') AS PercentageOfWorkforce
FROM LocationEmployeeCount
ORDER BY EmployeeCount DESC;

-- =======================================================
-- Compensation
-- =======================================================

-- Q4. How does compensation differ across departments?
WITH DepartmentSalaryAnalysis AS (
SELECT
	DepartmentID,
	Department,
	COUNT(EmployeeID) AS EmployeeCount,
	AVG(Salary) AS AverageDeptSalary,
	MIN(Salary) AS MinimumDeptSalary,
	MAX(Salary) AS MaximumDeptSalary
FROM clean.Employees
GROUP BY 
	DepartmentID,
	Department )
SELECT 
	Department,
	EmployeeCount,
	ROUND(AverageDeptSalary, 2) AS AverageDeptSalary,
	CAST(MinimumDeptSalary AS VARCHAR) + ' ' + '-' + ' ' + CAST(MaximumDeptSalary AS VARCHAR) AS DeptSalaryRange,
	ROW_NUMBER() OVER(ORDER BY AverageDeptSalary DESC) RankofDept
FROM DepartmentSalaryAnalysis;

-- Q5. How does compensation vary by job role?
SELECT
	JobRole,
	COUNT(EmployeeID) AS EmployeeCount,
	ROUND(AVG(Salary), 2) AS AverageRoleSalary,
	MIN(Salary) AS MinimumRoleSalary,
	MAX(Salary) AS MaximumRoleSalary
FROM clean.Employees
GROUP BY JobRole;

-- Q6. Which employees are unusually highly or poorly compensated relative to their department?
SELECT 
	EmployeeID,
	EmployeeName,
	Department,
	JobRole,
	Salary,
	ROUND(AVG(Salary) OVER(PARTITION BY Department), 2) AS DeptAverageSalary,
	ROUND(Salary - AVG(Salary) OVER(PARTITION BY Department), 2) AS DifferenceFromAvgSalary,
	ROW_NUMBER() OVER(PARTITION BY Department ORDER BY Salary DESC) AS RankWithinDepartment
FROM clean.Employees;

-- =======================================================
-- Attendance and workforce productivity
-- =======================================================

-- Q7. What is the overall attendance pattern?
WITH AttendanceRecordsCount AS (
SELECT 
	Status,
	COUNT(AttendanceID) AS NumberOfRecords
FROM clean.Attendance
GROUP BY Status )
SELECT
	Status,
	NumberOfRecords,
	CONCAT(CAST(NumberOfRecords AS FLOAT) / SUM(NumberOfRecords) OVER() * 100, '%') AS PercentageOfAttendanceRecord
FROM AttendanceRecordsCount
ORDER BY NumberOfRecords DESC;

-- Q8. Which departments have the best and worst attendance?
SELECT 
	e.Department,
	COUNT(a.attendanceid) AS TotalAttendanceRecord,
	COUNT(CASE WHEN a.Status = 'PRESENT' THEN 1 END) AS TotalPresent,
	COUNT(CASE WHEN a.Status = 'ABSENT' THEN 1 END) AS TotalAbsent,
	COUNT(CASE WHEN a.Status = 'LATE' THEN 1 END) AS TotalLate,
	COUNT(CASE WHEN a.Status = 'LEAVE' THEN 1 END) AS TotalLeave,
	CONCAT(ROUND(COUNT(CASE WHEN a.Status = 'PRESENT' THEN 1 END) / CAST(COUNT(a.attendanceid) AS FLOAT) * 100, 2), '%') AS AttendanceRate,
	CONCAT(ROUND(COUNT(CASE WHEN a.Status = 'ABSENT' THEN 1 END) / CAST(COUNT(a.attendanceid) AS FLOAT) * 100, 2), '%') AS AbsentRate,
	CONCAT(ROUND(COUNT(CASE WHEN a.Status = 'LATE' THEN 1 END) / CAST(COUNT(a.attendanceid) AS FLOAT) * 100, 2), '%') AS LateRate
FROM clean.Attendance AS a
LEFT JOIN clean.Employees AS e
ON a.EmployeeID = e.EmployeeID
GROUP BY e.Department
ORDER BY TotalAttendanceRecord DESC;

-- Q9. Which departments have the highest and lowest working hours?
SELECT
	e.Department,
	ROUND(AVG(a.HoursWorked), 2) AS AverageHours,
	MIN(a.HoursWorked) AS MinimumHours,
	MAX(a.HoursWorked) AS MaximumHours,
	SUM(a.HoursWorked) AS TotalHours
FROM clean.Employees AS e
INNER JOIN clean.Attendance AS a
ON e.EmployeeID = a.EmployeeID
GROUP BY e.Department
ORDER BY AverageHours DESC;

-- Q10. Which departments rely most heavily on overtime?
WITH EmployeeOT AS (
SELECT
	a.EmployeeID,
    e.Department,
    SUM(a.OvertimeHours) AS TotalOTPerEmployee
FROM clean.Attendance AS a
INNER JOIN clean.Employees AS e
ON a.EmployeeID = e.EmployeeID
GROUP BY a.EmployeeID, e.Department )
SELECT
    Department,
    ROUND(SUM(TotalOTPerEmployee), 2) AS TotalOvertimeHours,
    ROUND(AVG(TotalOTPerEmployee), 2) AS AverageOvertimeHours,
    COUNT(CASE WHEN TotalOTPerEmployee > 0 THEN 1 END) AS EmployeesWithOvertime,
    CONCAT(CAST(ROUND(COUNT(CASE WHEN TotalOTPerEmployee > 0 THEN 1 END) * 100.0 / COUNT(DISTINCT EmployeeID), 2) AS FLOAT), '%') AS PercentageEmployeesWithOvertime
FROM EmployeeOT
GROUP BY Department
ORDER BY PercentageEmployeesWithOvertime DESC;

-- Q11. How has working time changed over time?
SELECT
	FORMAT(DATETRUNC(month, AttendanceDate), 'MM,yyyy') AS AttendancePeriod,
	ROUND(SUM(HoursWorked), 2) AS TotalHoursWorked,
	ROUND(AVG(HoursWorked), 2) AS AverageHoursWorked,
	ROUND(SUM(Overtimehours), 2) AS TotalOTHours,
	ROUND(AVG(Overtimehours), 2) AS AverageOTHours
FROM clean.Attendance
GROUP BY FORMAT(DATETRUNC(month, AttendanceDate), 'MM,yyyy')
ORDER BY AttendancePeriod;

-- =======================================================
-- Peformance and training
-- =======================================================

-- Q12. Which departments have the strongest performance?
SELECT
	Department,
	COUNT(ReviewID) AS NumberOfReviews,
	ROUND(AVG(Performancerating), 2) AS AveragePerformanceRating,
	COUNT(CASE WHEN Performancerating = 1 THEN 1 END) AS Rate_1_Count,
	COUNT(CASE WHEN Performancerating = 2 THEN 1 END) AS Rate_2_Count,
	COUNT(CASE WHEN Performancerating = 3 THEN 1 END) AS Rate_3_Count,
	COUNT(CASE WHEN Performancerating = 4 THEN 1 END) AS Rate_4_Count,
	COUNT(CASE WHEN Performancerating = 5 THEN 1 END) AS Rate_5_Count
FROM clean.PerformanceReviews AS p
INNER JOIN clean.Employees AS e
ON p.EmployeeID = e.EmployeeID
GROUP BY Department
ORDER BY NumberOfReviews DESC;

-- Q13. Which departments receive the most training?
SELECT
	Department,
	COUNT(ReviewID) AS NumberOfReviews,
	ROUND(AVG(TrainingHours), 2) AS AverageTrainingHours,
	MIN(TrainingHours) AS MinimumTrainingHour,
	MAX(TrainingHours) AS MaximumTrainingHour,
	ROUND(SUM(TrainingHours), 2) AS TotalTrainingHour
FROM clean.PerformanceReviews AS p
INNER JOIN clean.Employees AS e
ON p.EmployeeID = e.EmployeeID
GROUP BY Department
ORDER BY TotalTrainingHour DESC;

-- Q14. Is more training associated with higher performance?
WITH EmployeeTrainingHours AS (
SELECT
	EmployeeID,
	COUNT(ReviewID) AS NumberOfReviews,
	SUM(TrainingHours) AS TotalTrainingHours,
	AVG(PerformanceRating) AS AveragePerformanceRating,
	CASE
		WHEN SUM(TrainingHours) BETWEEN 0 AND 10 THEN 'Very Low'
		WHEN SUM(TrainingHours) BETWEEN 11 AND 20 THEN 'Low'
		WHEN SUM(TrainingHours) BETWEEN 21 AND 30 THEN 'Medium'
		WHEN SUM(TrainingHours) BETWEEN 31 AND 40 THEN 'High'
		ELSE 'Very High'
	END AS TrainingHoursCategory
FROM clean.PerformanceReviews
GROUP BY EmployeeID )
SELECT
	TrainingHoursCategory,
	ROUND(SUM(TotalTrainingHours), 2) AS TotalTrainingHour,
	ROUND(AVG(TotalTrainingHours), 2) AS AverageTrainingHour,
	ROUND(AVG(AveragePerformanceRating), 2) AS AveragePerformanceRating,
	SUM(NumberOfReviews) AS TotalNummberOfReviews
FROM EmployeeTrainingHours
GROUP BY TrainingHoursCategory;

-- Q15. Does performance differ based on employee tenure?
WITH Tenure AS (
SELECT 
	EmployeeID,
	EmployeeName,
	CASE
		WHEN ExitDate IS NOT NULL THEN DATEDIFF(year, HireDate, ExitDate)
		ELSE DATEDIFF(year, HireDate, GETDATE())
	END AS EmployeeTenure
FROM clean.Employees )
SELECT
	CASE
		WHEN EmployeeTenure BETWEEN 0 AND 1 THEN 'Under 1 Year'
		WHEN EmployeeTenure BETWEEN 1 AND 3 THEN '1 - 3 Years'
		ELSE '3+ Years'
	END AS TenureBracket,
	COUNT(DISTINCT t.EmployeeID) AS NumberOfEmployees,
	ROUND(AVG(PerformanceRating), 2) AS AveragePerfromanceRating,
	ROUND(AVG(TrainingHours), 2) AS AverageTrainingHours
FROM Tenure AS t
LEFT JOIN clean.PerformanceReviews AS p
ON t.EmployeeID = p.EmployeeID
GROUP BY 	
	CASE
		WHEN EmployeeTenure BETWEEN 0 AND 1 THEN 'Under 1 Year'
		WHEN EmployeeTenure BETWEEN 1 AND 3 THEN '1 - 3 Years'
		ELSE '3+ Years'
	END;

-- =======================================================
-- Employee tenure and turnover
-- =======================================================

-- Q16. What is the average employee tenure/Overall tenure analysis
WITH Tenure AS (
SELECT 
	EmployeeID,
	EmployeeName,
	CASE
		WHEN ExitDate IS NOT NULL THEN DATEDIFF(year, HireDate, ExitDate)
		ELSE DATEDIFF(year, HireDate, GETDATE())
	END AS EmployeeTenure
FROM clean.Employees )
SELECT
	AVG(EmployeeTenure) AS AverageTenure,
	MIN(EmployeeTenure) AS MinimumTenure,
	MAX(EmployeeTenure) AS MaximumTenure
FROM Tenure;

-- Q17. Tenure analysis by department
WITH Tenure AS (
SELECT 
	EmployeeID,
	EmployeeName,
	CASE
		WHEN ExitDate IS NOT NULL THEN DATEDIFF(year, HireDate, ExitDate)
		ELSE DATEDIFF(year, HireDate, GETDATE())
	END AS EmployeeTenure
FROM clean.Employees )
SELECT
	Department,
	COUNT(t.EmployeeID) AS NumberOfEmployees,
	AVG(EmployeeTenure) AS AverageTenure,
	MIN(EmployeeTenure) AS MinimumTenure,
	MAX(EmployeeTenure) AS MaximumTenure
FROM Tenure AS t
INNER JOIN clean.Employees AS e
ON t.EmployeeID = e.EmployeeID
GROUP BY Department;

-- Q18. How many employees have left, and what are the main exit modes?
SELECT
	ExitMode,
	COUNT(EmployeeID) AS NumberOfExits,
	CONCAT((CAST(COUNT(EmployeeID) AS FLOAT) / (SELECT COUNT(EmployeeID) FROM clean.Employees)) * 100, '%') AS PercentageOfExits
FROM clean.Employees
WHERE ExitMode IS NOT NULL
GROUP BY ExitMode 
ORDER BY NumberOfExits DESC;

-- Q19. How has employee turnover changed over time?
SELECT
	YEAR(ExitDate) AS ExitYear,
	COUNT(EmployeeID) AS NumberOfExits,
	COALESCE(LAG(COUNT(EmployeeID)) OVER(ORDER BY YEAR(ExitDate)), 0) AS PreviousYearExits,
	CONCAT(
		COALESCE(
			CAST(
				ROUND(
					(COUNT(EmployeeID) - LAG(COUNT(EmployeeID)) OVER(ORDER BY YEAR(ExitDate))) * 100.0 
					/ LAG(COUNT(EmployeeID)) OVER(ORDER BY YEAR(ExitDate))
				, 2) 
			AS FLOAT)
		, 0), 
	'%') AS [%ChangeFromPreviousYear]
FROM clean.Employees
WHERE ExitDate IS NOT NULL
GROUP BY YEAR(ExitDate);

-- Q20. Which departments experience the most employee exits?
SELECT
	Department,
	COUNT(EmployeeID) AS EmployeeCount,
	COUNT(CASE WHEN EmploymentStatus = 'EXITED' THEN 1 END) AS NumberOfExits,
	CONCAT(ROUND(COUNT(CASE WHEN EmploymentStatus = 'EXITED' THEN 1 END)/CAST(COUNT(EmployeeID) AS FLOAT) * 100, 2), '%') AS ExitRate
FROM clean.Employees
GROUP BY Department;

-- Q21. How long do employees typically stay before leaving?
WITH Tenure AS (
SELECT 
	EmployeeID,
	EmployeeName,
	CASE
		WHEN ExitDate IS NOT NULL THEN DATEDIFF(year, HireDate, ExitDate)
		ELSE DATEDIFF(year, HireDate, GETDATE())
	END AS EmployeeTenure
FROM clean.Employees )
SELECT
	ExitMode,
	COUNT(t.EmployeeID) AS NumberOfExits,
	AVG(EmployeeTenure) AverageTenureBeforeExit,
	MIN(EmployeeTenure) AS MinimumTenure,
	MAX(EmployeeTenure)AS MaximumTenure
FROM clean.Employees AS e
INNER JOIN Tenure AS t
ON t.employeeid = e.employeeid
WHERE ExitMode IS NOT NULL
GROUP BY ExitMode
ORDER BY NumberOfExits DESC;

-- Q22. Are there signs of employee disengagement before exit?
WITH Tenure AS (
SELECT 
	EmployeeID,
	EmployeeName,
	Department,
	EmploymentStatus,
	ExitDate,
	ExitMode,
	CASE
		WHEN ExitDate IS NOT NULL THEN DATEDIFF(year, HireDate, ExitDate)
		ELSE DATEDIFF(year, HireDate, GETDATE())
	END AS EmployeeTenure
FROM clean.Employees )
, AttendanceSummary AS (
SELECT 
	EmployeeID,
	ROUND(AVG(HoursWorked), 2) AS AverageHoursWorked,
	ROUND(AVG(Overtimehours), 2) AS AverageOTHours,
	CONCAT(
		ROUND(
			(CAST(COUNT(CASE WHEN Status = 'PRESENT' THEN 1 END) AS FLOAT)
				/COUNT(AttendanceID)) * 100
		, 2) 
	, '%') AS AttendanceRate
FROM clean.Attendance
GROUP BY EmployeeID )
, PerformanceSummary AS (
SELECT 
	e.EmployeeID,
	COALESCE(ROUND(AVG(PerformanceRating), 2), 0) AS AveragePerformanceRating,
	COALESCE(ROUND(SUM(TrainingHours), 2), 0) AS TotalTrainingHours,
	MAX(ReviewDate) AS LastReviewDate
FROM clean.PerformanceReviews AS p
LEFT JOIN clean.Employees AS e
ON p.employeeid = e.employeeid
GROUP BY e.EmployeeID )
SELECT
	t.EmployeeID,
	EmployeeName,
	Department,
	COALESCE(ExitMode, 'N/A') AS ExitMode,
	EmployeeTenure,
	AveragePerformanceRating,
	TotalTrainingHours,
	AverageHoursWorked,
	AverageOTHours,
	AttendanceRate,
	LastReviewDate,
	ExitDate
FROM Tenure AS t
INNER JOIN AttendanceSummary AS a
ON t.EmployeeID = a.EmployeeID
INNER JOIN PerformanceSummary AS p
ON t.EmployeeID = p.EmployeeID
WHERE EmploymentStatus = 'EXITED';


