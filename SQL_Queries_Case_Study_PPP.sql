-- PART I: CLEANING THE DATA

-- 1. Write a query to check all the records whose NAICS codes are not provided.
SELECT NAICS_Codes, 
       NAICS_Industry_Description
FROM sba_industry_standards
WHERE NAICS_Codes='';


-- 2. Write a query to obtain the list of all different types of industry sectors covered under NAICS. 
SELECT NAICS_Industry_Description
FROM sba_industry_standards
WHERE NAICS_Codes='' AND NAICS_Industry_Description LIKE '%–%';


-- 3. Write a query to obtain the list of codes related to each industry sector assigned by NAICS.  
SELECT *
FROM (SELECT NAICS_Industry_Description, 
             IIF(NAICS_Industry_Description LIKE '%–%', SUBSTRING(NAICS_Industry_Description, 8, 2), ' ') AS Sector_code
FROM sba_industry_standards
WHERE NAICS_Codes='') main
WHERE Sector_code != ' '; 


-- 4. Write a query to obatin the title or name associated with each industry sector. 
SELECT *
FROM (SELECT NAICS_Industry_Description, 
             IIF(NAICS_Industry_Description LIKE '%–%', SUBSTRING(NAICS_Industry_Description, 8, 2), ' ') AS Sector_code,
			 ltrim(SUBSTRING(NAICS_Industry_Description, (CHARINDEX('–', NAICS_Industry_Description)) +1, LEN(NAICS_Industry_Description))) AS Sector_name
FROM sba_industry_standards
WHERE NAICS_Codes='') main
WHERE Sector_code != ' ';


-- 5. Write a query to create a table containing the details of each sector along with their name and code.
SELECT *
INTO sba_naics_sector_codes_and_names
FROM (SELECT NAICS_Industry_Description, 
             IIF(NAICS_Industry_Description LIKE '%–%', SUBSTRING(NAICS_Industry_Description, 8, 2), ' ') AS Sector_code,
			 ltrim(SUBSTRING(NAICS_Industry_Description, (CHARINDEX('–', NAICS_Industry_Description)) +1, LEN(NAICS_Industry_Description))) AS Sector_name
FROM sba_industry_standards
WHERE NAICS_Codes='') main
WHERE Sector_code != ' ';


-- 6. Write a query to insert records of those sectors whose sector code comes within mentioned range. 
INSERT INTO sba_naics_sector_codes_and_names
VALUES 
  ('Sector 31 – 33 – Manufacturing', 32, 'Manufacturing'), 
  ('Sector 31 – 33 – Manufacturing', 33, 'Manufacturing'), 
  ('Sector 44 - 45 – Retail Trade', 45, 'Retail Trade'),
  ('Sector 48 - 49 – Transportation and Warehousing', 49, 'Transportation and Warehousing');


-- 7. Write a query to update the sector names containing numerical sector code as part of cleaning the data. 
UPDATE sba_naics_sector_codes_and_names
SET Sector_name = 'Manufacturing'
WHERE Sector_code = 31;


-- PART II: EXPLORING THE DATA

-- 1. Write a query to display a summary of all approved loans in the year 2020 & 2021. 
SELECT Year(DateApproved) AS Approved_year,
       Count(LoanNumber) AS Number_of_loans_approved, 
	   Sum(InitialApprovalAmount) AS Total_amount_approved, 
	   Avg(InitialApprovalAmount) AS Average_loan_size,
	   Count(Distinct OriginatingLender) AS Unique_lenders
FROM sba_public_data
WHERE year(DateApproved) = 2020
GROUP BY year(DateApproved)
UNION
SELECT year(DateApproved) AS Approved_year,
       Count(LoanNumber) AS Number_of_loans_approved, 
	   Sum(InitialApprovalAmount) AS Total_amount_approved, 
	   Avg(InitialApprovalAmount) AS Average_loan_size,
	   Count(Distinct OriginatingLender) AS Unique_lenders
FROM sba_public_data
WHERE year(DateApproved) = 2021
GROUP BY year(DateApproved);


--2. Write a query to display the loan approved per lender by total amount, average amount and loan count in the year 2020 & 2021. 
SELECT year(DateApproved) AS Approved_year, 
       OriginatingLender,
       Sum(InitialApprovalAmount) AS Total_amount_approved, 
	   Avg(InitialApprovalAmount) AS Average_Loan_Size,
	   Count(LoanNumber) AS Number_of_loans_approved
FROM sba_public_data
WHERE year(DateApproved) IN (2020, 2021)
GROUP BY year(DateApproved), OriginatingLender
ORDER BY year(DateApproved) ASC, Total_amount_approved DESC;


--3. Write a query to retrieve top 20 industries who received the loans in the year of 2021.
SELECT TOP 20 Sector_name, 
              Sum(InitialApprovalAmount) AS Total_amount_approved,
			  Avg(InitialApprovalAmount) AS Average_Loan_Size
FROM sba_public_data A
     JOIN sba_naics_sector_codes_and_names B
ON LEFT(A.NAICSCode, 2) = B.Sector_code
WHERE year(DateApproved) = 2021
GROUP BY B.Sector_name
ORDER BY Total_amount_approved DESC


--4. Write a query to compare the count, sum, average, percentage by amount forgiven of the loans approved in the year 2020 & 2021.   total amount which was fully forgiven for the year of 2021.  
SELECT Count(LoanNumber) AS Number_of_loans_approved,
       Sum(CurrentApprovalAmount) AS Current_amount_approved,
	   Avg(CurrentApprovalAmount) AS Current_avg_loan_size,
       Sum(ForgivenessAmount) AS Forgiveness_amount,
	   Sum(ForgivenessAmount) * 100 / Sum(CurrentApprovalAmount) AS percentage_amount_forgiven
FROM sba_public_data
WHERE year(DateApproved) = 2020
UNION
SELECT Count(LoanNumber) AS Number_of_loans_approved,
       Sum(CurrentApprovalAmount) AS Current_amount_approved,
	   Avg(CurrentApprovalAmount) AS Current_avg_loan_size,
       Sum(ForgivenessAmount) AS Forgiveness_amount,
	   Sum(ForgivenessAmount) * 100 / Sum(CurrentApprovalAmount) AS percentage_amount_forgiven
FROM sba_public_data
WHERE year(DateApproved) = 2021


--5. Write a query to display the month and year in which maximum number of loans were approved by SBA.
SELECT TOP 1 Year(DateApproved), Month(DateApproved), COUNT(LoanNumber) AS Number_loans_approved
FROM sba_public_data
GROUP BY Year(DateApproved), Month(DateApproved)
ORDER BY Number_loans_approved desc;


--6. Write a query to calculate the percentage by amount of top 10 sectors for the year 2021.
WITH CTE AS 
(SELECT Sector_name, 
        Sum(InitialApprovalAmount) AS Total_amount_approved
FROM sba_public_data A
     JOIN sba_naics_sector_codes_and_names B
ON LEFT(A.NAICSCode, 2) = B.Sector_code
WHERE year(DateApproved) = 2021
GROUP BY B.Sector_name)
SELECT TOP 10 Sector_name, Total_amount_approved, (Total_amount_approved/(SELECT SUM(Total_amount_approved) FROM CTE)) *100 AS Percentage_by_amount
FROM CTE
ORDER BY Percentage_by_amount DESC;


--7. Write a query to display the total amount lend to each sector quarterly. 
SELECT DATEPART(Year, DateApproved) AS year,
       DATEPART(Quarter, DateApproved) AS quarter,
	   Sector_code,
	   Sector_name,
	   SUM(CurrentApprovalAmount) AS Amount_lent
FROM sba_public_data A
     JOIN sba_naics_sector_codes_and_names B
ON LEFT(A.NAICSCode, 2) = B.Sector_code
GROUP BY DATEPART(Year, DateApproved), DATEPART(Quarter, DateApproved), Sector_code, Sector_name
ORDER BY year, quarter, Sector_code;

--8. Write a query to calculate the running total of the approved loan for the Borrower whose name contain MORGAN in the year 2020.
SELECT Year(DateApproved),
       BorrowerName,
	   Sum(InitialApprovalAmount) OVER (ORDER BY InitialApprovalAmount Asc) AS Running_total
FROM sba_public_data
WHERE BorrowerName LIKE '%MORGAN' AND Year(DateApproved) = 2020; 

--9. Write a query to calculate the final amount approved as loan for top 5 sectors. 
SELECT TOP 5 Sector_code,
       Sector_name,
	   SUM(CurrentApprovalAmount) AS Amount_lent
FROM sba_public_data A
     JOIN sba_naics_sector_codes_and_names B
ON LEFT(A.NAICSCode, 2) = B.Sector_code
GROUP BY Sector_code, Sector_name
ORDER BY Amount_lent Desc;

--10. Write a query to display the second highest forgiveness amount through Paycheck Protection Program (PPP) for the Corporative Business. 
WITH CTE AS 
( SELECT Sector_code,
       Sector_name,
	   ForgivenessAmount,
	   ROW_NUMBER() OVER (ORDER BY ForgivenessAmount DESC) AS Row_number_of_Amount
FROM sba_public_data A
     JOIN sba_naics_sector_codes_and_names B
ON LEFT(A.NAICSCode, 2) = B.Sector_code
WHERE ProcessingMethod = 'PPP' AND BusinessType = 'Corporation' )
SELECT *
FROM CTE 
WHERE Row_number_of_Amount = 2;













