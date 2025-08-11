-- Drop table if exists
IF OBJECT_ID('dbo.DimDate', 'U') IS NOT NULL
    DROP TABLE dbo.DimDate;
GO

-- Drop functions if they already exist
IF OBJECT_ID('dbo.fn_GetEasterSunday', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_GetEasterSunday;
GO
IF OBJECT_ID('dbo.fn_GetNthWeekdayOfMonth', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_GetNthWeekdayOfMonth;
GO

-- Function to get Easter Sunday (used for some NZ holidays)
CREATE FUNCTION dbo.fn_GetEasterSunday(@Year INT)
RETURNS DATE
AS
BEGIN
    DECLARE @a INT = @Year % 19;
    DECLARE @b INT = @Year / 100;
    DECLARE @c INT = @Year % 100;
    DECLARE @d INT = @b / 4;
    DECLARE @e INT = @b % 4;
    DECLARE @f INT = (@b + 8) / 25;
    DECLARE @g INT = (@b - @f + 1) / 3;
    DECLARE @h INT = (19 * @a + @b - @d - @g + 15) % 30;
    DECLARE @i INT = @c / 4;
    DECLARE @k INT = @c % 4;
    DECLARE @l INT = (32 + 2 * @e + 2 * @i - @h - @k) % 7;
    DECLARE @m INT = (@a + 11 * @h + 22 * @l) / 451;
    DECLARE @Month INT = (@h + @l - 7 * @m + 114) / 31;
    DECLARE @Day INT = ((@h + @l - 7 * @m + 114) % 31) + 1;

    RETURN DATEFROMPARTS(@Year, @Month, @Day);
END;
GO

-- Function to get Nth weekday of a month
CREATE FUNCTION dbo.fn_GetNthWeekdayOfMonth(@Year INT, @Month INT, @Weekday INT, @Nth INT)
RETURNS DATE
AS
BEGIN
    DECLARE @FirstOfMonth DATE = DATEFROMPARTS(@Year, @Month, 1);
    DECLARE @DayOfWeek INT = DATEPART(WEEKDAY, @FirstOfMonth); -- 1=Sunday, 7=Saturday (depends on DATEFIRST)
    DECLARE @Offset INT = (@Weekday - @DayOfWeek + 7) % 7;
    RETURN DATEADD(DAY, @Offset + (@Nth - 1) * 7, @FirstOfMonth);
END;
GO

-- Create DimDate table
CREATE TABLE dbo.DimDate (
    DateKey INT PRIMARY KEY,
    FullDate DATE NOT NULL,
    Year INT NOT NULL,
    MonthNumber INT NOT NULL,
    MonthName VARCHAR(20) NOT NULL,
    QuarterNumber INT NOT NULL,
    QuarterName VARCHAR(10) NOT NULL,
    DayNumber INT NOT NULL,
    DayName VARCHAR(20) NOT NULL,
    WeekNumber INT NOT NULL,
    DayOfYear INT NOT NULL,
    IsWeekend BIT NOT NULL,
    IsBusinessDay BIT NOT NULL,
    Season VARCHAR(15) NOT NULL,
    FirstDayOfMonth DATE NOT NULL,
    LastDayOfMonth DATE NOT NULL,
    IsHoliday BIT NOT NULL,
    HolidayName VARCHAR(50) NULL
);

-- Variables for range
DECLARE @StartDate DATE = '1930-01-01';
DECLARE @EndDate DATE = DATEFROMPARTS(YEAR(GETDATE()) + 5, 12, 31);

-- Tally table CTE
;WITH N AS (
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_objects
),
Dates AS (
    SELECT DATEADD(DAY, n, @StartDate) AS d
    FROM N
    WHERE n <= DATEDIFF(DAY, @StartDate, @EndDate)
)
INSERT INTO dbo.DimDate
SELECT
    CONVERT(INT, FORMAT(d, 'yyyyMMdd')) AS DateKey,
    d AS FullDate,
    YEAR(d) AS Year,
    MONTH(d) AS MonthNumber,
    DATENAME(MONTH, d) AS MonthName,
    DATEPART(QUARTER, d) AS QuarterNumber,
    CONCAT('Q', DATEPART(QUARTER, d)) AS QuarterName,
    DAY(d) AS DayNumber,
    DATENAME(WEEKDAY, d) AS DayName,
    DATEPART(ISO_WEEK, d) AS WeekNumber,
    DATEPART(DAYOFYEAR, d) AS DayOfYear,
    CASE WHEN DATENAME(WEEKDAY, d) IN ('Saturday', 'Sunday') THEN 1 ELSE 0 END AS IsWeekend,
    0 AS IsBusinessDay, -- placeholder, update later
    CASE 
        WHEN MONTH(d) IN (12, 1, 2) THEN 'Summer'
        WHEN MONTH(d) IN (3, 4, 5) THEN 'Autumn'
        WHEN MONTH(d) IN (6, 7, 8) THEN 'Winter'
        ELSE 'Spring'
    END AS Season,
    DATEFROMPARTS(YEAR(d), MONTH(d), 1) AS FirstDayOfMonth,
    EOMONTH(d) AS LastDayOfMonth,
    0 AS IsHoliday, -- placeholder, update later
    NULL AS HolidayName
FROM Dates;

-- Mark NZ public holidays
UPDATE d
SET IsHoliday = 1,
    HolidayName = h.HolidayName
FROM dbo.DimDate d
JOIN (
    SELECT 
        DateValue,
        HolidayName
    FROM (
        -- Static holidays
        SELECT DATEFROMPARTS(y, 1, 1) AS DateValue, 'New Year''s Day' AS HolidayName FROM (SELECT DISTINCT Year FROM dbo.DimDate) q(y)
        UNION ALL
        SELECT DATEFROMPARTS(y, 2, 6), 'Waitangi Day' FROM (SELECT DISTINCT Year FROM dbo.DimDate) q(y)
        UNION ALL
        SELECT DATEFROMPARTS(y, 4, 25), 'ANZAC Day' FROM (SELECT DISTINCT Year FROM dbo.DimDate) q(y)
        -- Good Friday & Easter Monday
        UNION ALL
        SELECT DATEADD(DAY, -2, dbo.fn_GetEasterSunday(y)), 'Good Friday' FROM (SELECT DISTINCT Year FROM dbo.DimDate) q(y)
        UNION ALL
        SELECT DATEADD(DAY, 1, dbo.fn_GetEasterSunday(y)), 'Easter Monday' FROM (SELECT DISTINCT Year FROM dbo.DimDate) q(y)
        -- Labour Day (4th Monday of October)
        UNION ALL
        SELECT dbo.fn_GetNthWeekdayOfMonth(y, 10, 2, 4), 'Labour Day' FROM (SELECT DISTINCT Year FROM dbo.DimDate) q(y)
    ) Holidays
) h ON d.FullDate = h.DateValue;

-- Mark business days (not weekend and not holiday)
UPDATE dbo.DimDate
SET IsBusinessDay = CASE WHEN IsWeekend = 0 AND IsHoliday = 0 THEN 1 ELSE 0 END;




SELECT TOP 20 * FROM dbo.DimDate

-- Show a sample of holidays and business days
SELECT TOP 20
    FullDate,
    DayName,
    IsWeekend,
    IsHoliday,
    HolidayName,
    IsBusinessDay
FROM dbo.DimDate
WHERE IsHoliday = 1 OR IsWeekend = 1
ORDER BY FullDate;


--pure business days, not weekend, not holiday
SELECT TOP 20
    FullDate,
    DayName,
    IsWeekend,
    IsHoliday,
    HolidayName,
    IsBusinessDay
FROM dbo.DimDate
WHERE IsBusinessDay = 1
ORDER BY FullDate;

ALTER TABLE dbo.DimDate
ADD FormattedDate AS 
    CONVERT(CHAR(10), FullDate, 105) PERSISTED;

