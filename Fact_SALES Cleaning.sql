Create database Depi_Project_Cleaning
use Depi_Project_Cleaning

--Data Inspection----------------
SELECT *
FROM [FACT_SALES]
WHERE 
    Quantity IS NULL
    OR Unit_Price IS NULL
    OR Customer_ID IS NULL
    OR Order_Priority IS NULL
	OR City_ID IS Null
    OR LOWER(LTRIM(RTRIM(Order_Priority))) NOT IN ('high','medium','low')
    OR (
        TRY_CONVERT(date, Transaction_Date, 23) IS NULL 
        AND TRY_CONVERT(date, Transaction_Date, 105) IS NULL
       )
    OR Quantity > (
        SELECT AVG(Quantity) + 3 * STDEV(Quantity) FROM Fact_Sales
      );



	  -----Counting Total rows containing Nulls in Data----
SELECT 
    COUNT(*) AS Total_Error_Rows
FROM Fact_Sales
WHERE 
    Quantity IS NULL
    OR Unit_Price IS NULL
    OR Customer_ID IS NULL
    OR Order_Priority IS NULL
    OR LOWER(LTRIM(RTRIM(Order_Priority))) NOT IN ('high','medium','low')
    OR (
        TRY_CONVERT(date, Transaction_Date, 23) IS NULL 
        AND TRY_CONVERT(date, Transaction_Date, 105) IS NULL
       )
    OR Quantity > (
        SELECT AVG(Quantity) + 3 * STDEV(Quantity) FROM Fact_Sales WHERE Quantity IS NOT NULL
      );


-----Counting Total rows containing missing Data----

	  SELECT 
  COUNT(*) AS Total_Rows,
  SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS Missing_Quantity,
  SUM(CASE WHEN Unit_Price IS NULL THEN 1 ELSE 0 END)    AS Missing_UnitPrice,
  SUM(CASE WHEN Customer_ID IS NULL THEN 1 ELSE 0 END)   AS Missing_Customer,
  SUM(CASE WHEN Order_Priority IS NULL THEN 1 ELSE 0 END) AS Missing_Priority,
  SUM(CASE WHEN City_ID IS NULL THEN 1 ELSE 0 END) AS Missing_City


FROM Fact_Sales;


-------Detect Duplicates in Transaction_ID
SELECT 
    Transaction_ID,
    COUNT(*) AS Duplicate_Count
FROM Fact_Sales
GROUP BY Transaction_ID
HAVING COUNT(*) > 1;

--------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
-------------Data cleaning-------------------------------------------------------


---- Correction of Null values in Order priority 

SELECT [Transaction_ID],[Customer_ID],[City_ID],[Order_Priority]
FROM Fact_Sales
WHERE Order_Priority IS NULL;

UPDATE Fact_Sales
SET Order_Priority = 'Medium'
WHERE Order_Priority IS NULL;


------------ Correction of Null values in Customer_ID
SELECT [Transaction_ID],[City_ID],[Order_Priority],[Customer_ID]
FROM Fact_Sales
WHERE Customer_ID IS NULL;


UPDATE Fact_Sales
SET Customer_ID = 0
WHERE Customer_ID IS NULL;

----------------Correction of Null values in uint_Price

SELECT [Transaction_ID],[City_ID],[Order_Priority],[Customer_ID],[Unit_Price]
FROM Fact_Sales
WHERE Unit_Price IS NULL;


UPDATE Fact_Sales
SET Unit_Price = (SELECT AVG(Unit_Price) FROM Fact_Sales)
WHERE Unit_Price IS NULL;


----------------Correction of Null values in uint_quantity

SELECT [Transaction_ID],[City_ID],[Order_Priority],[Customer_ID],[Unit_Price],[Total_Sales],[Quantity]
FROM Fact_Sales
WHERE Quantity IS NULL;

UPDATE Fact_Sales
SET Quantity = Total_Sales/ Unit_Price
WHERE Quantity IS NULL
;

-------Correction of Non-Customized Data in Order_priority

SELECT TOP 50
    Transaction_ID,
    Customer_ID,
    Order_Priority,
    Total_Sales
FROM Fact_Sales;

----Trimming and make letters all small in Order_priority----
UPDATE Fact_Sales
SET Order_Priority = LOWER(LTRIM(RTRIM(Order_Priority)));

---Captalize each Word (High-Low-Medium)

UPDATE Fact_Sales
SET Order_Priority = 
    CASE 
        WHEN Order_Priority = 'high' THEN 'High'
        WHEN Order_Priority = 'medium' THEN 'Medium'
        WHEN Order_Priority = 'low' THEN 'Low'
        ELSE Order_Priority
    END;

	-------Delete Duplicates in Transaction_ID
SELECT 
    Transaction_ID,
    COUNT(*) AS Duplicate_Count
FROM Fact_Sales
GROUP BY Transaction_ID
HAVING COUNT(*) > 1;

	
WITH Duplicates AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY Transaction_ID 
            ORDER BY Transaction_ID
        ) AS rn
    FROM Fact_Sales
)
DELETE FROM Duplicates
WHERE rn > 1;

	----- Manging Outliers in Data------
	SELECT Transaction_ID,
    Customer_ID,
    Order_Priority,
    Total_Sales,
	Quantity
FROM Fact_Sales
WHERE Quantity > (
    SELECT AVG(Quantity) + 3 * STDEV(Quantity)
    FROM Fact_Sales
);

UPDATE Fact_Sales
SET Quantity = Sub.AvgQty + 3 * Sub.StdevQty
FROM Fact_Sales
CROSS JOIN (
    SELECT 
        AVG(Quantity) AS AvgQty,
        STDEV(Quantity) AS StdevQty
    FROM Fact_Sales
) AS Sub
WHERE Quantity > Sub.AvgQty + 3 * Sub.StdevQty;

----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------

----Validation of Cleaning------

---Total errors zero

SELECT 
    COUNT(*) AS Total_Error_Rows
FROM Fact_Sales
WHERE 
    Quantity IS NULL
    OR Unit_Price IS NULL
    OR Customer_ID IS NULL
    OR Order_Priority IS NULL
    OR LOWER(LTRIM(RTRIM(Order_Priority))) NOT IN ('high','medium','low')
    OR (
        TRY_CONVERT(date, Transaction_Date, 23) IS NULL 
        AND TRY_CONVERT(date, Transaction_Date, 105) IS NULL
       
      );



	  -------------------No missing Data-----------------

SELECT 
  COUNT(*) AS Total_Rows,
  SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS Missing_Quantity,
  SUM(CASE WHEN Unit_Price IS NULL THEN 1 ELSE 0 END)    AS Missing_UnitPrice,
  SUM(CASE WHEN Customer_ID IS NULL THEN 1 ELSE 0 END)   AS Missing_Customer,
  SUM(CASE WHEN Order_Priority IS NULL THEN 1 ELSE 0 END) AS Missing_Priority,
  SUM(CASE WHEN City_ID IS NULL THEN 1 ELSE 0 END) AS Missing_City

FROM Fact_Sales;


-------- No Duplicates in TransactionID--------------------
SELECT 
    Transaction_ID,
    COUNT(*) AS Duplicate_Count
FROM Fact_Sales
GROUP BY Transaction_ID
HAVING COUNT(*) > 1;

