# HR Workforce Analysis SQL Project

## Project Overview

This project explores HR and workforce data using Microsoft SQL Server.

The objective was to take a set of raw, intentionally messy HR datasets, investigate and clean the data, perform exploratory and advanced analysis, and build reusable workforce reports.

Rather than starting with predefined answers, I first examined the structure and quality of the data, identified the issues present, and applied appropriate business rules before using the cleaned data for analysis.

## The project covers:

- Workforce composition
- Compensation
- Attendance and working hours
- Overtime
- Employee performance
- Training
- Employee tenure
- Employee exits and turnover
- Workforce reporting

---

## Project Workflow

Raw CSV Files → SQL Server → Raw Schema → Data Investigation → Data Cleaning & Business Rules → Clean Schema → Exploratory Data Analysis → Advanced Data Analysis → Workforce Reporting Views

---

## Tools

- Microsoft SQL Server (SSMS)

---

# 1. Dataset & Database Structure

The project contains four related tables:

| Table | Rows | Purpose |
| :--- | :--- | :--- |
| Departments | 10 | Department and location reference data |
| Employees | 1,003 raw | Employee demographic, employment and compensation information |
| Attendance | 20,000 | Employee attendance, working hours and overtime |
| PerformanceReviews | 2,797 | Performance reviews, training hours and reviewer information |

```text
The main relationships are:

Departments
     │
     │ DepartmentID
     ↓
Employees
   │       │
   │       │
   ↓       ↓
Attendance   PerformanceReviews
                  │
                  │ ReviewerEmployeeID
                  ↓
              Employees
```
Each employee can have multiple attendance records and multiple performance reviews.

ReviewerEmployeeID also references the Employees table, allowing the reviewer to be identified from the employee information.

The raw employee table contained duplicate records, so EmployeeID was not treated as unique until the data had been investigated and cleaned.

---

# 2. Data Import & Database Setup

The four datasets were provided as CSV files and imported into SQL Server.

I used a raw/clean schema structure so that the original imported data could be preserved while cleaned and properly typed versions were created separately.

This allowed me to:

- retain the original raw data for reference;
- investigate data-quality issues before changing anything;
- apply cleaning rules without modifying the source data;
- use the cleaned tables for analysis.
  
The dataset was initially loaded into the raw schema, while the cleaned versions were created in the clean schema.

### Raw Data

- Departments.csv
- Employees.csv
- Attendance.csv
- PerformanceReviews.csv

### SQL Setup

```sql
CREATE DATABASE HR_Workforce_Analytics;
GO

CREATE SCHEMA raw;
GO

CREATE SCHEMA clean;
GO

CREATE SCHEMA report;
GO
```

---

# 3. Data Cleaning

Before performing analysis, I inspected the raw tables to understand the types of data-quality issues present.

The goal was not simply to remove anything that looked unusual. I first investigated the issues and then applied a logical rule based on the meaning of the field.

Some of the issues identified included:

- Duplicate employee records
- Missing values
- Inconsistent text casing and whitespace
- Multiple date formats
- Negative working and overtime hours
- Zero salary values
- Performance ratings outside the expected 1–5 range
- Inconsistent employment status and exit dates
- Missing exit modes for some exited employees

---

## 3.1 Employees

The employee table contained several data-quality issues, including duplicate employee records, inconsistent text formatting, missing department/location information, zero salary values, mixed date formats and employment status/date inconsistencies.

I first investigated the duplicate EmployeeID values and determined that the duplicate records were exact duplicates. I therefore retained one record for each employee.

Other cleaning steps included:

- Converting EmployeeID and DepartmentID to integers
- Removing unwanted whitespace
- Standardising text values using uppercase where appropriate
- Standardising HireDate and ExitDate
- Using the department reference table to fill missing department/location information where appropriate
- Treating zero salary as missing
- Standardising employment status
- Ensuring active employees did not retain an exit date
  
**View Employees Cleaning Query**

--- 

## 3.2 Departments

The Departments table was used primarily as a reference table.

Cleaning focused on ensuring that department identifiers and descriptive fields were consistently represented and could be reliably used when joining to employee data.

**View Departments Cleaning Query**

---

## 3.3 Attendance

The Attendance table contained inconsistent status formatting, mixed date formats, negative values for working hours and overtime, and missing values.

I investigated these issues before applying the cleaning rules.

The cleaning included:

- Converting AttendanceID and EmployeeID to integers
- Standardising AttendanceDate
- Standardising attendance statuses
- Removing negative values from HoursWorked and OvertimeHours
- Applying different rules to working hours depending on attendance status
- Handling overtime values that did not logically apply to non-working statuses
- Handling missing values according to the attendance status
  
For example, an employee recorded as absent or on leave should not have meaningful working hours recorded for that day, so those values were handled differently from missing values for employees who were present.

**View Attendance Cleaning Query**

---

## 3.4 Performance Reviews

The Performance Reviews table contained mixed date formats, missing values and performance ratings outside the expected range.

I investigated the valid rating range before deciding how to handle invalid ratings.

Cleaning included:

- Converting ReviewID, EmployeeID and ReviewerEmployeeID to integer
- Standardising ReviewDate
- Identifying performance ratings outside the expected 1–5 range
- Treating invalid ratings as missing rather than assigning an arbitrary valid rating
  
The table was retained at the review level because an employee can have multiple performance reviews over time.

**View Performance Reviews Cleaning Query**

---

# 4. Exploratory Data Analysis

After cleaning the data, I used exploratory data analysis to understand the database before moving into more detailed business analysis.

The EDA focused on establishing the basic structure of the workforce and understanding the available measures and dimensions.

Questions explored included:

- How many employees are in the workforce?
- How many departments are there?
- How is the workforce distributed across departments?
- What employment types exist?
- What is the gender distribution?
- What are the salary ranges?
- How many attendance and performance records are available?
- What period does the attendance data cover?
- What attendance statuses exist?
- What performance ratings exist?
- What exit modes exist?
- What are the ranges for working hours, overtime and training hours?
  
This stage helped establish what was actually present in the database before moving into deeper analysis.

**View EDA Queries**

---

# 5. Advanced Data Analysis 

The advanced analysis moved from simply understanding the data to answering business questions about the workforce.

I grouped the analysis into five areas.

---

## 5.1 Workforce Composition

I examined how the workforce is distributed across:

- Departments
- Employment types
- Gender
- Locations
  
The analysis also calculated each group's share of the overall workforce.

This provides HR with a clearer picture of the composition and concentration of the workforce.

---

## 5.2 Compensation

The compensation analysis examined:

- Average salary by department
- Minimum and maximum salary by department
- Salary differences across job roles
- Employee salary compared with their departmental average
- Employee ranking within their department
  
This moves beyond simply calculating average salary and provides context for identifying employees whose compensation differs substantially from others in the same department.

---

## 5.3 Attendance & Workforce Productivity

The attendance analysis examined:

- Overall attendance patterns
- Present, absent, late and leave records
- Attendance rates by department
- Absence and lateness rates
- Working hours by department
- Overtime usage by department
- Employees receiving overtime
- Working-hour and overtime trends over time
  
The overtime analysis was performed at employee level first and then aggregated to department level so that departments could be compared using both total overtime and the proportion of employees working overtime.

--- 

## 5.4 Performance & Training

The performance and training analysis examined:

- Average performance rating by department
- Distribution of performance ratings
- Training hours by department
- Training-hour categories
- The relationship between training and performance
- Performance across employee tenure groups
- 
For the training analysis, I treated the relationship as an association rather than proof of causation. The purpose was to investigate whether employees with higher training exposure also tended to have higher performance ratings.

---

## 5.5 Tenure & Employee Turnover

The final area focused on employee retention and turnover.

The analysis examined:

- Average employee tenure
- Tenure by department
- Number of employee exits
- Exit modes
- Exit trends over time
- Departmental exit rates
- Tenure before exit
- Employee-level indicators that may provide context around disengagement before exit
  
The final disengagement analysis combined information from attendance, performance, training, overtime and employee tenure to provide a broader view of employees who eventually exited the organisation.

**View Advanced Data Analysis Queries**

---

# 6. Workforce Reporting

After completing the analysis, I created two reusable SQL views designed to provide employee-level reporting for HR.

---

## 6.1 Active Employee Workforce Report

The active employee report combines employee information with workforce activity and performance information.

The report includes:

- Employee details
- Gender
- Department
- Job role
- Location
- Employment type
- Salary
- Annual salary
- Hire date
- Employee tenure
- Total hours worked
- Total overtime
- Average hours worked
- Total training hours
- Latest performance rating
- Reviewer information
  
The purpose of the report is to provide HR with a consolidated view of the current workforce without requiring the underlying tables to be queried separately.

**View Active Employee Report**

---

## 6.2 Exited Employee Workforce Report

The exited employee report focuses specifically on employees who have left the organisation.

It includes:

- Employee details
- Department and job role
- Hire date
- Exit date
- Exit mode
- Tenure at exit
- Salary
- Latest performance rating
- Total hours worked
- Overtime
- Average hours worked
- Training hours
  
This provides a consolidated view that can be used to examine employee exits alongside their employment history, performance and workforce activity.

**View Exited Employee Report**

---

# 7. SQL Techniques Used

The project gave me an opportunity to apply SQL techniques across different stages of an analytical workflow.

### Data Preparation

- CAST
- TRY_CAST
- TRY_CONVERT
- COALESCE
- TRIM
- UPPER
- CASE
- Date functions
  
### Data Exploration & Aggregation

- GROUP BY
- Aggregate functions
- Conditional aggregation
- HAVING
- ORDER BY

### Combining Data

- INNER JOI
- LEFT JOIN

### Advanced Analysis

- CTE
- Subqueries
- Window functions
- PARTITION BY
- ROW_NUMBER()
- RANK()
- LAG()
- FIRST_VALUE()
- Comparative calculations

### Reporting

- SQL View
- Multiple CTEs

---

# 8. Project Outcome

This project took the data through a complete analytical workflow:

Raw data → Investigation → Cleaning → Exploration → Analysis → Reporting

The main lesson from the project was that writing SQL queries is only one part of the analytical process. Before calculating a metric, I needed to understand the data, identify quality issues, decide how those issues should be handled, and consider whether the resulting metric actually represented the business question being asked.

The final result is a cleaned and analysis-ready HR dataset together with SQL analysis and reusable workforce reports.

---

## Repository Structure

```text
HR-Workforce-Analytics/
│
├── README.md
│
├── data/
│   ├── Departments.csv
│   ├── Employees.csv
│   ├── Attendance.csv
│   └── PerformanceReviews.csv
│
└── sql/
    ├── Data_Cleaning_Departments_Table.sql
    ├── Data_Cleaning_Employees_Table.sql
    ├── Data_Cleaning_Attendance_Table.sql
    ├── Data_Cleaning_PerformanceReview_Table.sql
    ├── Exploratory_Data_Analysis.sql
    ├── Advanced_Data_Analysis.sql
    ├── Active_Employee_Workforce_Report.sql
    └── Exited_Employee_Workforce_Report.sql
```
