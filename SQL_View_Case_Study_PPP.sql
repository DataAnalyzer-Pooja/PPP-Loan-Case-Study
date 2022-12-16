Create VIEW PPP_Summary AS
SELECT 
	Sector_code,
    Sector_name,
	year(DateApproved) year_approved,
	month(DateApproved) month_Approved,
	OriginatingLender, 	
	BorrowerState,
	Race,
	Gender,
	Ethnicity,
	Count(LoanNumber) Number_of_Approved,
	Sum(CurrentApprovalAmount) Current_Approved_Amount,
	Avg (CurrentApprovalAmount) Current_Average_loan_size,
	Sum(ForgivenessAmount) Amount_Forgiven,
	Sum(InitialApprovalAmount) Approved_Amount,
	Avg (InitialApprovalAmount) Average_loan_size
FROM 
	sba_public_data A
	inner join sba_naics_sector_codes_and_names B
	ON left(A.NAICSCode, 2) = B.Sector_code
group by 
	Sector_code,  
    Sector_name,
	year(DateApproved),
	month(DateApproved),
	OriginatingLender, 	
	BorrowerState,
	Race,
	Gender,
	Ethnicity
