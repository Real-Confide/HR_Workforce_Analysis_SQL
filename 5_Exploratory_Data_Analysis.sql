-- How many employees?
SELECT 
	COUNT(EmployeeID) AS NumberOfEmployees
FROM clean.Employees;

-- How many departments?  
SELECT
	COUNT(DepartmentID) AS NumberOfDepartments
FROM clean.Departments;

-- What is the number of employees by department?
SELECT
	Department,
	COUNT(EmployeeID) AS NumberOfEmployees
FROM clean.Employees
GROUP BY Department
ORDER BY NumberOfEmployees DESC;

-- What is the number of employees by employment type?
SELECT
	EmploymentType,
	COUNT(EmployeeID) AS NumberOfEmployees
FROM clean.Employees
GROUP BY EmploymentType
ORDER BY NumberOfEmployees DESC; 

-- What is the number of employees by gender?
SELECT
	Gender,
	COUNT(EmployeeID) AS NumberOfEmployees
FROM clean.Employees
GROUP BY Gender
ORDER BY NumberOfEmployees DESC;

-- What is the lowest, highest and average salary?
SELECT
	MIN(Salary) AS LowestSalary,
	MAX(Salary) AS HighestSalary,
	ROUND(AVG(Salary), 2) AS AverageSalary
FROM clean.Employees;

-- How many attendance records?
SELECT
	COUNT(AttendanceID) AS CountOfAttendanceRecord
FROM clean.Attendance;
 
-- How many performance reviews?
SELECT
	COUNT(ReviewID) AS CountOfPerformanceReviews
FROM clean.PerformanceReviews;

-- What years does the data cover?
SELECT
	MIN(AttendanceDate) AS FirstDate,
	MAX(AttendanceDate) AS LastDate
FROM clean.Attendance;

-- What is the lowest, highest and average hours worked?
SELECT
	MIN(HoursWorked) AS LowestHourWorked,
	MAX(HoursWorked) AS HighestHourWorked,
	ROUND(AVG(HoursWorked), 2) AS AverageHourWorked
FROM clean.Attendance;

-- What is the lowest, highest and average overtime hours worked?
SELECT
	MIN(OvertimeHours) AS LowestOTHourWorked,
	MAX(OvertimeHours) AS HighestOTHourWorked,
	ROUND(AVG(OvertimeHours), 2) AS AverageOTHourWorked
FROM clean.Attendance;

-- What are the possible employment statuses?
SELECT DISTINCT
	EmploymentStatus
FROM clean.Employees;

-- What are the possible exit modes?
SELECT DISTINCT
	ExitMode
FROM clean.Employees
WHERE ExitMode IS NOT NULL;

-- What job roles exist?
SELECT DISTINCT
	JobRole
FROM clean.Employees;

-- What attendance statuses exist?
SELECT DISTINCT
	Status
FROM clean.Attendance;

-- What performance ratings exist?
SELECT DISTINCT	
	PerformanceRating
FROM clean.PerformanceReviews
WHERE PerformanceRating IS NOT NULL
ORDER BY PerformanceRating ASC;

-- What is the lowest, highest and average training hours?
SELECT
	MIN(TrainingHours) AS LowestTrainingHour,
	MAX(TrainingHours) AS HighestTrainingHour,
	ROUND(AVG(TrainingHours), 2) AS AverageTrainingHour
FROM clean.PerformanceReviews;

