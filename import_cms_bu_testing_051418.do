
/* final vars for innovator data:
aconame_cms mssp_num cms_pioneer_num aco_start ACO_comp_new_PY1 ACO_comp_new_PY2 ACO_comp_new_PY3 sharedsavings_PY1 sharedsavings_PY2 sharedsavings_PY3 benchmarkminusexp_PY1 benchmarkminusexp_PY2 benchmarkminusexp_PY3 finalsharerate_PY1 finalsharerate_PY2 finalsharerate_PY3 n_ab_PY1 n_ab_PY2 n_ab_PY3
*/

**********************************************************************
/*	PROJECT: 		Update CMS data with PY3 and PY4
	PROGRAMMED BY: 	Alex Mainor
	DATE CREATED: 	September 21, 2016
	LAST EDITED:	April 30,2018 (BU)
*/
***********************************************************************


foreach year in _PY1 _PY2 _PY3 _PY4 {  //BU 11/2017: added PY4

	clear
	set more off
	
	*Import CSV from CMS website
	*Website: https://data.cms.gov/ACO/Medicare-Shared-Savings-Program-Accountable-Care-O/yuq5-65xt
	
	import delimited using "/Volumes/NSACO/NSACO Data Master/CMS/Data files/CMS raw data/Medicare_Shared_Savings_Program_Accountable_Care_Organizations_Performance_`year'_Results.csv"

	*Change varnames to the varnames used in the linking key
	
	capture rename *aconamelbnordbaifapplicable aconame_cms //Year 1 variable name
	capture rename acodoingbusinessasdbaorlegalbusi aconame_cms //Year 2 variable name
	capture rename aco_name aconame_cms //Year 3 variable name
	capture rename agreementstartdate start_date
	capture rename initial_start_date start_date
	capture rename aco_service_area bene_states
	capture rename totalbenchmarkminusassignedbenef totalbenchmarkminassignedben
	capture rename diabetescomposite dmcomposite
	
	*Aligning Year 3 track variables with Year 1 and 2
	capture gen track_y3="."
	capture replace track_y3="1" if track_1==1
	capture replace track_y3="2" if track_2==1
	capture replace track_y3="3" if track_3==1
	capture rename track_y3 track
	capture drop track_1 track_2 track_3
	
	*Aligning Year 4 track variables with Year 1,2,3  (BU 11/2017)  // CHECK TO MAKE SURE WANT TO USE "CURRENT TRACK" instead of "INITIAL TRACK"
	capture gen track_y4="."
	capture replace track_y4="1" if current_track_1==1
	capture replace track_y4="2" if current_track_2==1
	capture replace track_y4="3" if current_track_3==1
	capture rename track_y4 track
	capture drop track_1 track_2 track_3
	
	
	
	*Remove trailing blanks from track and stateswhere
	replace track = trim(track)
	capture replace stateswherebeneficiariesreside = trim(stateswherebeneficiariesreside)
	capture rename stateswherebeneficiariesreside bene_states
	capture rename aco_state bene_states //bu added 11/2017

	*Change numerical string variables to numerical categorical. y3_reportedquality temporarily used here to avoid problems with variable names in subsequent runs of loop*
	capture rename participateinadvancepaymentmodel advancepaymentmodel
	capture rename adv_pay advancepaymentmodel //Y3 only, already numerical
	capture rename successfullyreportedquality5 reportedquality
	capture rename reportedquality5 reportedquality
	capture rename metthequalityperformancestandard y3_reportedquality
	
	*Change string categorical to numerical categorical. Don't use encode since order of responses may differ across years
	replace track="1" if track=="Track1"
	replace track="2" if track=="Track2"
	capture replace advancepaymentmodel="0" if advancepaymentmodel=="No "
	capture replace advancepaymentmodel="1" if advancepaymentmodel=="Yes "
	capture replace reportedquality="1" if reportedquality=="No"
	capture replace reportedquality="2" if reportedquality=="Yes"
	capture replace reportedquality="3" if reportedquality=="No*"
	capture replace reportedquality="1" if reportedquality=="No "
	capture replace reportedquality="2" if reportedquality=="Yes "
	capture replace y3_reportedquality="2" if y3_reportedquality=="Yes "
	capture replace y3_reportedquality="1" if y3_reportedquality=="No "

	*Removing non-numeric characters from variables that should be numeric for destring below
	capture destring totalbenchmarkexpenditures, replace ignore("$")
	capture destring totalexpenditures, replace ignore("$")
	capture destring totalbenchmarkminassignedben, replace ignore("$")
	capture destring v17, replace ignore("%")
	capture destring generatedsavingslosses12, replace ignore("$")
	capture destring earnedsharedsavingspaymentsowelo, replace ignore("$")

	*Removing string variables from ACO quality measures*
	capture foreach var of varlist aco1* aco2* aco3* aco4* aco5* aco6* aco7* {
		destring `var', replace ignore("-,N/A")
	}

	*Destring Track and quality*
	capture foreach var of varlist track advancepaymentmodel {
		destring `var', replace
	} 

	*Re-Label Track and quality*
	label define trackL 1 "Track 1" 2 "Track 2" 3 "Track 3"
	label values track trackL
	label define advanceL 0 "Doesn't participate in Advance Payment model" 1 "Participates in Advance Payment model"
	label values advancepaymentmodel advanceL
	
	*Destring Quality*
	capture destring reportedquality, replace
	capture destring y3_reportedquality, replace
	
	*Quality reporting - Y1 and Y2*
	label define qualreportL 1 "No successful report for either Y1 or Y2" 2 "Successfully reported for Y1&Y2" 3 "Successfully reported for Y2 only"
	capture label values reportedquality qualreportL
	*Quality reporting - Y3*
	label define qualreporty3 1 "No successful report for Y3" 2 "Successfully reported for Y3"
	capture label values y3_reportedquality qualreporty3
	*Rename variable to align w/ Y1 and Y2 files*
	capture rename y3_reportedquality reportedquality
	
	*Remove numbers from variable names (these are from footnotes in original files)
	capture rename generatedsavingslosses12 generatedsavingslosses
	capture gen  earnedsavingsowelosses = gensaveloss
	capture  rename gensaveloss generatedsavingslosses // (BU 11/2017: 
	capture rename qualityscore6 qualityscore //Y2 only	
	capture rename qualscore qualityscore // Y4

	*Before destringing qualityscore, have to change "P4R" to missing value
	capture replace qualityscore=".p" if qualityscore=="P4R" //Y2 only
	capture destring qualityscore, replace ignore("%,P4R")
	
	*Inconsistent/switching labels for benchmark spending differences each year*
	*Weird order/repetition MUST be retained - CMS uses same variable names across years for different variables*
	capture rename v10 expenditurepercent
	capture rename totalbenchmarkexpendituresminust expendituredollar
	capture rename v17 expenditurepercent
	capture rename totalbenchmarkminassignedben expenditurepercent
	capture rename totalbenchmarkminassignedben expendituredollar

	*Destring new spending labels*
	capture destring expendituredollar, replace ignore("$")  //BU: 11/2017: added capture as 2016 doesn't have this var;check this var ; find analogue for 2014 
	capture destring expenditurepercent, replace ignore("%")
	capture destring earnedsavingsowelosses, replace ignore("$,-,,")

	
*Matching ACO Names to CMS format 

	replace aconame_cms=strtrim(aconame_cms)

	replace aconame_cms="AAMC Collaborative Care Network, LLC" if aconame_cms=="AAMC Collaborative Care Network"

	*replace aconame_cms="Beth Israel Deaconess Physician Organization" if aconame_cms=="Beth Israel Deaconess Hospital-Plymouth"
	**THESE ARE NOT THE SAME
	*There was an alliance formed, but these are still separate ACOs. Plymouth official ACO name is Jordan Community ACO
	*http://www.bidplymouth.org/body.cfm?id=10&action=detail&ref=355
	
	replace aconame_cms="Jordan Community ACO" if aconame_cms=="Beth Israel Deaconess Hospital-Plymouth"

	replace aconame_cms="Cedars-Sinai Medical Care Foundation" if aconame_cms=="Cedars-Sinai Accountable Care, LLC"

	replace aconame_cms="Physicians Accountable Care Organization, LLC" if aconame_cms=="Physicians Accountable Care Organization LLC"
	
	replace aconame_cms="St. John Providence Partners in Care, LLC" if (aconame_cms=="Partners In Care ACO, Inc."|aconame_cms=="Partners in Care")&start_date=="01/01/2013"
		*Matches MSSP performance data for "Partners in Care ACO, Inc."
		*http://www.sjppartnersincare.org/documents/MSSP-Quality-Data-Information.pdf
		
		*This is NOT the same as the other "Partners In Care ACO, Inc." with start date of 1/1/14
		
	replace aconame_cms="Arizona Connected Care, LLC" if aconame_cms=="Southern Arizona Accountable Care Organization, LLC"
		*http://www.azconnectedcare.org/who-we-are/public-reporting-information/
		*https://www.cms.gov/Medicare/Medicare-Fee-for-Service-Payment/sharedsavingsprogram/Downloads/ACO-Information-List.pdf
		*http://www.commonwealthfund.org/~/media/Files/Publications/Case%20Study/2012/Jan/1575_Carluzzo_Tucson_case%20study_01_12_2012.pdf
		
	replace aconame_cms="AAMC Collaborative Care Network, LLC" if aconame_cms=="AAMC Collaborative Care Network" 
	replace aconame_cms="Accountable Care Clinical Services, PC" if aconame_cms=="ACCOUNTABLE CARE CLINICAL SERVICES, PC"
	replace aconame_cms="APCN-ACO, A Medical Professional Corporation" if aconame_cms=="APCN-ACO, A MEDICAL PROFESSIONAL CORPORATION"

	replace aconame_cms="Central Utah Clinic, P.C." if aconame_cms=="Revere Health" //Revere is current, but listed as central Utah in MSSP current list
	*http://reverehealth.com/aco-public-report/
	
	replace aconame_cms="A.M. Beajow, M.D. Internal Medicine Associates ACO, P.C" if aconame_cms=="Copeland - Beajow Medical Institute, Chtd DBA Internal Medicine Associates"
	replace aconame_cms="Hartford Healthcare Accountable Care Organization, Inc." if aconame_cms=="HARTFORD HEALTHCARE ACCOUNTABLE CARE ORGANIZATION, INC."
	replace aconame_cms="Heartland" if aconame_cms=="Mosaic Life Care" //Mosaic is current, but listed as Heartland in MSSP current list
	replace aconame_cms="Maryland Accountable Care Organization of Eastern Shore LLC" if aconame_cms=="MARYLAND ACCOUNTABLE CARE ORGANIZATION OF EASTERN SHORE LLC"
	replace aconame_cms="Maryland Accountable Care Organization of Western MD LLC" if aconame_cms=="MARYLAND ACCOUNTABLE CARE ORGANIZATION OF WESTERN MD LLC"
	replace aconame_cms="MCM Accountable Care Organization, LLC" if aconame_cms=="MCM ACCOUNTABLE CARE ORGANIZATION, LLC"
	replace aconame_cms="Medical Practitioners For Affordable Care, LLC" if aconame_cms=="Medical Practitioners for Affordable Care, LLC"
	replace aconame_cms="Nature Coast ACO LLC" if aconame_cms=="NATURE COAST ACO LLC"
	replace aconame_cms="Orange Accountable Care" if aconame_cms=="ACO Health Partners, LLC"
		*http://www.orangehealthaco.net/About.aspx
	replace aconame_cms="Southern Maryland Collaborative Care LLC" if aconame_cms=="Southern Maryland Integrated Care, LLC"
	replace aconame_cms="WESTMED Medical Group, P.C." if aconame_cms=="WESTMED Medical Group"
	replace aconame_cms="Yavapai Accountable Care, LLC" if aconame_cms=="Yavapai Accountable Care"
	replace aconame_cms="Franciscan Northwest Physicians Health Network, LLC" if aconame_cms=="Rainier Health Network"
		*http://www.rainierhealthnetwork.com/Home

*Matching names to most current CMS PY3 format*
	replace aconame_cms="Premier ACO Physicians Network, LLC" if aconame_cms=="Premier ACO Physician Network, LLC"
	replace aconame_cms="Primary Care Alliance" if aconame_cms=="Primary Care Alliance LLC"
	replace aconame_cms="Alexian Brothers Accountable Care Organization, LLC" if aconame_cms=="Alexian Brothers Accountable Care Organization"
	replace aconame_cms="Millennium Accountable Care Organization, LLC" if aconame_cms=="Millennium Accountable Care Organization"
	replace aconame_cms="Scottsdale Health Partners, LLC" if aconame_cms=="Scottsdale Health Partners"
	replace aconame_cms="Arizona Care Network" if aconame_cms=="Arizona Care Network LLC"
	replace aconame_cms="Caribbean Accountable Care, Inc." if aconame_cms=="Caribbean Accountable Care, LLC"
	replace aconame_cms="Marshfield Clinic, Inc." if aconame_cms=="Marshfield Clinic"
	replace aconame_cms="National ACO" if aconame_cms=="National ACO, LLC"
	replace aconame_cms="Lahey Clinical Performance ACO" if aconame_cms=="Lahey Clinical Performance Accountable Care Organization, LLC"
	replace aconame_cms="Primary PartnerCare ACO Independent Practice Association, Inc." if aconame_cms=="Primary PartnerCare Associates IPA, Inc."
	replace aconame_cms="HCP ACO California, LLC" if aconame_cms=="HCP ACO CA LLC"
	replace aconame_cms="Barnabas Health Care Network" if aconame_cms=="Barnabas Health ACO-North, LLC"
	replace aconame_cms="KCMPA-ACO, LLC" if aconame_cms=="KCMPA"
	replace aconame_cms="JFK Health ACO" if aconame_cms=="JFK Population Health Company, LLC"
	replace aconame_cms="Methodist Alliance for Patients and Physicians" if aconame_cms=="Methodist Patient Centered ACO"
	replace bene_stat = strtrim(bene_states)
	replace aconame_cms = "Mercy ACO, LLC (Iowa)" if (aconame_cms=="Mercy ACO" | aconame_cms=="Mercy ACO, LLC") & (bene_states=="Iowa" | bene_states=="Iowa, Illinois" | bene_states=="IL, IA" | bene_states=="")
	
	*Rename variables to label year
	
		*First change super-long varnames to shorter
		
		*capture rename totalbenchmarkexpendituresminust totalbenchmarkexpendminus
			*Renamed above to expendituredollar due to Y3 var names
		capture rename earnedsharedsavingspaymentsowelo earnedsavingsowelosses
		capture rename n_ab totalassignedbeneficiaries  // (BU 11/2017:
		capture rename abtotexp totalexpenditures
		capture rename abtotbnchmk totalbenchmarkexpenditures	
	*	capture rename   gensaveloss earnedsavingsowelosses  //BU: check what this should be renamed to.
		
		
		****
		drop earnedsavingsowelosses
		****
		
	rename * *`year'
		rename aconame_cms`year' aconame_cms
		rename start_date`year' start_date
	
	gen baromaident=1 if aconame_cms=="Baroma Health Partners"&bene_states`year'=="Florida"
		replace baromaident=2 if aconame_cms=="Baroma Health Partners"&bene_states`year'=="Texas,  Louisiana"
		capture lab var baromaident "Baroma Health Partners identifier for merging"
		capture lab define baromaidentL 1 "Florida" 2 "Texas,  Louisiana"
		capture lab val baromaident baromaidentL
	
	*Dropping Y3 variables from Y1 and Y2 files
		capture drop track_y3_PY1
		capture drop track_y3_PY2

		
**Added BU 11/2017 to account for PY4
capture rename dm_comp`year'  dmcomposite`year'
capture destring dmcomposite`year', replace force
capture gen aco12`year'= .
capture gen reportedquality`year'= .		
capture	replace reportedquality`year'=1 if start_date== 20454 & qualityscore==1 // (BU 11/2017: added due to lack of explicit var in 2016)
capture	replace reportedquality`year'=0 if start_date== 20454 & qualityscore!=1  // (BU 11/2017: added due to lack of explicit var in 2016)	
	
saveold "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/MSSP Quality and Savings`year'.dta", replace

}
		
use "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/MSSP Quality and Savings_PY1.dta", clear

merge 1:1 aconame_cms start_date baromaident using "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/MSSP Quality and Savings_PY2.dta"
rename _merge merge1
/*
drop _merge
merge 1:1 aconame_cms start_date baromaident using "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/MSSP Quality and Savings_PY2.dta"
drop _merge
merge 1:1 aconame_cms start_date baromaident using "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/MSSP Quality and Savings_PY2.dta"
drop _merge
*/
*Replace y1 missings with y2 data if y2 starter
*no quality score var in y1
gen qualityscore_PY1=.
*destring earnedsavingsowelosses_PY2, replace ignore("$,-,,")

*Creating new blanks for measures added in Y3, to add in those measures for Y2 starters*
foreach varstub in aco34 aco35 aco36 aco37 aco38 aco39 aco40 aco41  {
	gen `varstub'_PY2=.
	
}

*****************************************************
**********MOVE Y2 to Y1 FOR 2014 STARTERS************
*****************************************************

*Moving Y2 variables into Y1 for Y2 starters*
foreach varstub in track advancepaymentmodel totalassignedbeneficiaries totalbenchmarkexpenditures totalexpenditures expendituredollar expenditurepercent generatedsavingslosses /* earnedsavingsowelosses */ reportedquality qualityscore aco1 aco2 aco3 aco4 aco5 aco6 aco7 aco8 aco9 aco10 aco11 aco12 aco13 aco14 aco15 aco16 aco17 aco18 aco19 aco20 aco21 dmcomposite aco22 aco23 aco24 aco25 aco26 aco27 aco28 aco29 aco30 aco31 cadcomposite aco32 aco33 {
	*Don't do the replacement for Pioneer switchers (want their data to still be _PY2)
	replace `varstub'_PY1=`varstub'_PY2 if (start_date=="01/01/2014" & !inlist(aconame_cms,"HCP ACO California, LLC","Seton Accountable Care Organization, Inc.","Premier Choice ACO, Inc.","Physician Health Partners, LLC", "Franciscan Alliance ACO"))
	replace `varstub'_PY2=. if (start_date=="01/01/2014" & !inlist(aconame_cms,"HCP ACO California, LLC","Seton Accountable Care Organization, Inc.","Premier Choice ACO, Inc.","Physician Health Partners, LLC", "Franciscan Alliance ACO"))
}

foreach varstub in bene_states {
	replace `varstub'_PY1=`varstub'_PY2 if (start_date=="01/01/2014" & !inlist(aconame_cms,"HCP ACO California, LLC","Seton Accountable Care Organization, Inc.","Premier Choice ACO, Inc.","Physician Health Partners, LLC", "Franciscan Alliance ACO"))
	replace `varstub'_PY2="." if (start_date=="01/01/2014" & !inlist(aconame_cms,"HCP ACO California, LLC","Seton Accountable Care Organization, Inc.","Premier Choice ACO, Inc.","Physician Health Partners, LLC", "Franciscan Alliance ACO"))
}


	*Note for future: Need to check merge. Sort by aconame_cms and double-check that all merged properly. Edit names in cleaning files as necessary
	*ALL should match. Sometimes names are very different. Look for _____ dba ______ (a good resource is Googling the name folllowed by "public reporting")
		
		*Need to use start date as well because some ACOs have the same name (Mercy ACO)
		*Need to use baromaident since two Baroma Health Partners have same start date
		
*Note for future: Need to check merge. Sort by aconame_cms and double-check that all merged properly. Edit names in cleaning files as necessary
				
				*The following mismatches are okay:
					
					*If merge3==2 (using only) and start_date=="01/01/2014" since the ACO SSP PUF and MSSP y1 data are from 2013
					
					*If merge3==1 (master only) and ACO dropped out of MSSP program between 2013 and 2014
					*See "List of dropped MSSP ACOs" for details
						
gen mssp_drop= (merge1==2)


replace aconame_cms="Health Connect ACO, LLC" if aconame_cms=="Health Connect ACO,LLC"
*rename reportedquality_PY* reportedquality_mssp_PY*

drop merge1

*Aligning now-merged Baroma names to Y3 names*
replace aconame_cms="BAROMA Healthcare Holdings" if aconame_cms=="Baroma Health Partners" & bene_states_PY1=="Texas,  Louisiana"
replace aconame_cms="Baroma Healthcare International, LLC" if aconame_cms=="BAROMA Health Partners" & bene_states_PY1=="Florida" & start_date=="01/01/2013"
replace aconame_cms="Baroma Healthcare, LLC" if aconame_cms=="Baroma Health Partners" & bene_states_PY1=="Florida" & start_date=="01/01/2014"

*Aligning other name mismatches/changes to Y3 names*
replace aconame_cms="Renown Accountable Care, LLC" if aconame_cms=="R TotalHealth, LLC"
replace aconame_cms="HCP ACO California, LLC" if aconame_cms=="HCO ACO California, LLC"
replace aconame_cms="CHS ACO" if aconame_cms=="Chicago Health System ACO, LLC"

*For fuzzy match name checking*
saveold "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/MSSP Quality and Savings_PY1_PY2.dta", replace

merge 1:1 aconame_cms start_date using "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/MSSP Quality and Savings_PY3.dta"

*****************************************************
**********MOVE Y3 to Y2 FOR 2014 STARTERS************
*****************************************************

*Note - ACO22-ACO26 were dropped in Y3, so not in this loop (nothing to push back)*
foreach varstub in track advancepaymentmodel totalassignedbeneficiaries totalbenchmarkexpenditures totalexpenditures /*expendituredollar expenditurepercent */ generatedsavingslosses /*earnedsavingsowelosses*/ reportedquality qualityscore aco1 aco2 aco3 aco4 aco5 aco6 aco7 aco8 aco9 aco10 aco11 aco13 aco14 aco15 aco16 aco17 aco18 aco19 aco20 dmcomposite aco21 aco27 aco28 aco30 aco31 aco33 aco34 aco35 aco36 aco37 aco38 aco39 aco40 aco41{
	*Don't do the replacement for Pioneer switchers (want their data to still be _PY2)
	replace `varstub'_PY2=`varstub'_PY3 if (start_date=="01/01/2014" & !inlist(aconame_cms, "HCP ACO California, LLC", "Seton Accountable Care Organization, Inc.","Premier Choice ACO, Inc.","Physician Health Partners, LLC", "Franciscan Alliance ACO"))
	*Some ACO quality measures dropped in PY3 data - replace PY2 as blank*
	replace `varstub'_PY3=. if (start_date=="01/01/2014" & !inlist(aconame_cms,"HCP ACO California, LLC","Seton Accountable Care Organization, Inc.","Premier Choice ACO, Inc.","Physician Health Partners, LLC", "Franciscan Alliance ACO"))
	
}

foreach varstub in bene_states {
	replace `varstub'_PY2=`varstub'_PY3 if (start_date=="01/01/2014" & !inlist(aconame_cms,"HCP ACO California, LLC","Seton Accountable Care Organization, Inc.","Premier Choice ACO, Inc.","Physician Health Partners, LLC", "Franciscan Alliance ACO" ))
	replace `varstub'_PY3="." if (start_date=="01/01/2014" & !inlist(aconame_cms,"HCP ACO California, LLC", "Seton Accountable Care Organization, Inc.","Premier Choice ACO, Inc.","Physician Health Partners, LLC", "Franciscan Alliance ACO"))
}

*****************************************************
**********MOVE Y3 to Y1 FOR 2015 STARTERS************
*****************************************************

*NO IDEA IF THIS IS RIGHT*
*Note - ACO22-ACO26 were dropped in Y3, so not in this loop (nothing to push back)*

*Y3 quality vars didn't exist in PY1, generating blanks*
foreach varstub in aco34 aco35 aco36 aco37 aco38 aco39 aco40 aco41 {
	gen `varstub'_PY1=.
	}

foreach varstub in track advancepaymentmodel totalassignedbeneficiaries totalbenchmarkexpenditures totalexpenditures expendituredollar expenditurepercent generatedsavingslosses /*earnedsavingsowelosses*/ reportedquality qualityscore aco1 aco2 aco3 aco4 aco5 aco6 aco7 aco8 aco9 aco10 aco11 aco13 aco14 aco15 aco16 aco17 aco18 aco19 aco20 dmcomposite aco21 aco27 aco28 aco30 aco31 aco33 aco34 aco35 aco36 aco37 aco38 aco39 aco40 aco41{
	*Don't do the replacement for Pioneer switchers (want their data to still be _PY2)
	replace `varstub'_PY1=`varstub'_PY3 if (start_date=="01/01/2015" & !inlist(aconame_cms,"HCP ACO California, LLC","Seton Accountable Care Organization, Inc.","Premier Choice ACO, Inc.","Physician Health Partners, LLC", "Franciscan Alliance ACO","Genesys PHO, L.L.C."))
	*Some ACO quality measures dropped in PY3 data - replace PY2 as blank*
	replace `varstub'_PY3=. if (start_date=="01/01/2015" & !inlist(aconame_cms,"HCP ACO California, LLC","Seton Accountable Care Organization, Inc.","Premier Choice ACO, Inc.","Physician Health Partners, LLC", "Franciscan Alliance ACO","Genesys PHO, L.L.C."))
}

foreach varstub in bene_states {
	replace `varstub'_PY1=`varstub'_PY3 if (start_date=="01/01/2015" & !inlist(aconame_cms,"HCP ACO California LLC","Seton Accountable Care Organization, Inc.","Premier Choice ACO, Inc.","Physician Health Partners, LLC", "Franciscan Alliance ACO","Genesys PHO, L.L.C."))
	replace `varstub'_PY3="." if (start_date=="01/01/2015" & !inlist(aconame_cms,"HCP ACO California, LLC","Seton Accountable Care Organization, Inc.","Premier Choice ACO, Inc.","Physician Health Partners, LLC", "Franciscan Alliance ACO","Genesys PHO, L.L.C."))
}
drop _merge

merge 1:1 aconame_cms start_date using "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/MSSP Quality and Savings_PY4.dta"

forvalues x= 1/4 {
label var generatedsavingslosses_PY`x' "Generated Savings/Losses in PY`x'"
}


gen aco42_PY1=.
gen aco42_PY2=.
gen aco42_PY3=.
*****************************************************
**********MOVE Y4 to Y1 FOR 2016 STARTERS************
*****************************************************
foreach varstub in track advancepaymentmodel totalassignedbeneficiaries totalbenchmarkexpenditures totalexpenditures /*expendituredollar expenditurepercent*/ generatedsavingslosses /* earnedsavingsowelosses */ reportedquality qualityscore aco1 aco2 aco3 aco4 aco5 aco6 aco7 aco8 aco9 aco10 aco11 aco12 aco13 aco14 aco15 aco16 aco17 aco18 aco19 aco20 aco21 dmcomposite /*aco22 aco23 aco24 aco25 aco26 */ aco27 aco28 /* aco29 */aco30 aco31/*cadcomposite  aco32 */ aco33 aco34 aco35 aco36 aco37 aco38 aco39 aco40 aco41 aco42{
	*Don't do the replacement for Pioneer switchers (want their data to still be _PY2)  //BU: or PY4 for Franciscan alliance or Genesys PHO
	*moving Y4 varaibles into Y1 for Y4 starters
	replace `varstub'_PY1=`varstub'_PY4 if (start_date=="01/01/2016" & !inlist(aconame_cms,"HCP ACO California, LLC", "Seton Accountable Care Organization, Inc.","Premier Choice ACO, Inc.","Physician Health Partners, LLC", "Franciscan Alliance ACO", "Genesys PHO, L.L.C."))
	replace `varstub'_PY4=. if (start_date=="01/01/2016" & !inlist(aconame_cms,"HCP ACO California, LLC","Seton Accountable Care Organization, Inc.","Premier Choice ACO, Inc.","Physician Health Partners, LLC", "Franciscan Alliance ACO", "Genesys PHO, L.L.C."))
	gen `varstub'_PY5 = `varstub'_PY4 if aconame_cms=="Franciscan Alliance ACO"  
	replace `varstub'_PY4= `varstub'_PY3 if aconame_cms==  "Franciscan Alliance ACO"  
	replace `varstub'_PY3=. if aconame_cms== "Franciscan Alliance ACO"  
	
	/*replace `varstub'_PY5 = `varstub'_PY4 if aconame_cms=="POM ACO"
	replace `varstub'_PY4 = `varstub'_PY3 if aconame_cms=="POM ACO"
	replace `varstub'_PY3 = `varstub'_PY2 if aconame_cms=="POM ACO"	
	replace `varstub'_PY2 = `varstub'_PY1 if aconame_cms=="POM ACO" */
	}

foreach varstub in bene_states {
	replace `varstub'_PY1=`varstub'_PY4 if (start_date=="01/01/2016" & !inlist(aconame_cms,"HCP ACO California, LLC", "Seton Accountable Care Organization, Inc.","Premier Choice ACO, Inc.","Physician Health Partners, LLC", "Franciscan Alliance ACO", "Genesys PHO, L.L.C."))
	replace `varstub'_PY4="." if (start_date=="01/01/2016" & !inlist(aconame_cms,"HCP ACO California, LLC","Seton Accountable Care Organization, Inc.","Premier Choice ACO, Inc.","Physician Health Partners, LLC", "Franciscan Alliance ACO", "Genesys PHO, L.L.C."))	
	gen `varstub'_PY5 = `varstub'_PY4 if aconame_cms=="Franciscan Alliance ACO"  
	replace `varstub'_PY4= `varstub'_PY3 if aconame_cms==  "Franciscan Alliance ACO"  
	replace `varstub'_PY3="" if aconame_cms== "Franciscan Alliance ACO"  
	}

*****************************************************
**********MOVE Y4 to Y2 FOR 2015 STARTERS************
*****************************************************
*Re-aligning var names changed for proper looping with previous file*

foreach varstub in track advancepaymentmodel totalassignedbeneficiaries totalbenchmarkexpenditures totalexpenditures /* expendituredollar expenditurepercent*/  generatedsavingslosses /* earnedsavingsowelosses */ reportedquality qualityscore aco1 aco2 aco3 aco4 aco5 aco6 aco7 aco8 aco9 aco10 aco11 aco12 aco13 aco14 aco15 aco16 aco17 aco18 aco19 aco20 aco21 dmcomposite /*aco22  aco23  aco24 aco25 aco26 */ aco27 aco28 /*aco29 */ aco30 aco31 /*cadcomposite  aco32 */ aco33 aco34 aco35 aco36 aco37 aco38 aco39 aco40 aco41 aco42 {
	*Don't do the replacement for Pioneer switchers (want their data to still be _PY2)
	replace `varstub'_PY2=`varstub'_PY4 if (start_date=="01/01/2015" & !inlist(aconame_cms,"HCP ACO California, LLC", "Seton Accountable Care Organization, Inc.","Premier Choice ACO, Inc.","Physician Health Partners, LLC", "Franciscan Alliance ACO", "Genesys PHO, L.L.C."))
	replace `varstub'_PY4=. if (start_date=="01/01/2015" & !inlist(aconame_cms,"HCP ACO California, LLC", "Seton Accountable Care Organization, Inc.","Premier Choice ACO, Inc.","Physician Health Partners, LLC", "Franciscan Alliance ACO", "Genesys PHO, L.L.C."))
	*moving Y4 varaibles into Y1 for Y4 starters
}

foreach varstub in bene_states {
	replace `varstub'_PY2=`varstub'_PY4 if (start_date=="01/01/2015" & !inlist(aconame_cms,"HCP ACO California, LLC","Seton Accountable Care Organization, Inc.","Premier Choice ACO, Inc.","Physician Health Partners, LLC", "Franciscan Alliance ACO", "Genesys PHO, L.L.C."))
	replace `varstub'_PY4="." if (start_date=="01/01/2015" & !inlist(aconame_cms,"HCP ACO California, LLC","Seton Accountable Care Organization, Inc.","Premier Choice ACO, Inc.","Physician Health Partners, LLC", "Franciscan Alliance ACO", "Genesys PHO, L.L.C."))
	*moving Y4 varaibles into Y1 for Y4 starters
}

*ADD save for this step  
*****************************************************
**********MOVE Y4 to Y3 FOR 2014 STARTERS************
*****************************************************
foreach varstub in track advancepaymentmodel totalassignedbeneficiaries totalbenchmarkexpenditures totalexpenditures /*expendituredollar expenditurepercent */ generatedsavingslosses /*earnedsavingsowelosses*/ reportedquality qualityscore aco1 aco2 aco3 aco4 aco5 aco6 aco7 aco8 aco9 aco10 aco11 aco12 aco13 aco14 aco15 aco16 aco17 aco18 aco19 aco20 aco21 dmcomposite /*aco22 aco23  aco24 aco25 aco26*/aco27 aco28 /*aco29 */ aco30 aco31 /*cadcomposite  aco32 */ aco33 aco34 aco35 aco36 aco37 aco38 aco39 aco40 aco41 aco42 {
	*Don't do the replacement for Pioneer switchers (want their data to still be _PY2)
	replace `varstub'_PY3=`varstub'_PY4 if (start_date=="01/01/2014" & !inlist(aconame_cms,"HCP ACO California, LLC","Seton Accountable Care Organization, Inc.","Premier Choice ACO, Inc.","Physician Health Partners, LLC", "Franciscan Alliance ACO", "Genesys PHO, L.L.C."))
	replace `varstub'_PY4=. if (start_date=="01/01/2014" & !inlist(aconame_cms,"HCP ACO California, LLC","Seton Accountable Care Organization, Inc.","Premier Choice ACO, Inc.","Physician Health Partners, LLC", "Franciscan Alliance ACO", "Genesys PHO, L.L.C."))
	*moving Y4 varaibles into Y1 for Y4 starters
	replace `varstub'_PY1=. if aconame_cms=="POM ACO"
}

foreach varstub in bene_states {
	replace `varstub'_PY3=`varstub'_PY4 if (start_date=="01/01/2014" & !inlist(aconame_cms,"HCP ACO California, LLC","Seton Accountable Care Organization, Inc.","Premier Choice ACO, Inc.","Physician Health Partners, LLC", "Franciscan Alliance ACO", "Genesys PHO, L.L.C."))
	replace `varstub'_PY4="." if (start_date=="01/01/2014" & !inlist(aconame_cms,"HCP ACO California, LLC","Seton Accountable Care Organization, Inc.","Premier Choice ACO, Inc.","Physician Health Partners, LLC", "Franciscan Alliance ACO", "Genesys PHO, L.L.C."))
	*moving Y4 varaibles into Y1 for Y4 starters
}




*Re-aligning var names changed for proper looping with previous file*

rename expendituredollar_PY* totalbenchmarkexpendminus_PY*
rename expenditurepercent_PY* totalbenchmarkminassignedben_PY*

***Note reformatting dates code below works but would be much simpler to use gen [datevar] = date(start_date, "MDY"), rather than having to have separate steps for month, day, year [perhaps this wasn't available as STATA command when this wwas originally written? (BU 01/19/2017)
*Reformatting Dates*
gen mo=substr(start_date,1,2)
gen da=substr(start_date,4,2)
gen yr=substr(start_date,7,4)
destring mo da yr, replace

drop start_date
gen start_date=mdy(mo,da,yr)
format start_date %td
drop mo da yr

drop current_start_date_PY3	

order aconame_cms *_PY1 *_PY2 *_PY3 *_PY4
drop current_start_date_PY4 //dropping this var  as not needed (BU 11/2017)

capture drop agree_type_PY4 agreement_period_num_PY4 initial_track_1_PY4 initial_track_2_PY4 initial_track_3_PY4 current_track_1_PY4 current_track_2_PY4 current_track_3_PY4 advancepaymentmodel_PY4 aim_PY4  sav_rate_PY4 minsavperc_PY4 bnchmkminexp_PY4 /*generatedsavingslosses_PY4 */ earnsaveloss_PY4 met_qps_PY4 qualityscore_PY4 prior_sav_adj_PY4 updatedbnchmk_PY4 histbnchmk_PY4  totalexpenditures_PY4 adv_pay_amt_PY4 adv_pay_recoup_PY4 qualperfshare_PY4 finalsharerate_PY4 per_capita_exp_all_esrd_by1_PY4 per_capita_exp_all_dis_by1_PY4 per_capita_exp_all_agdu_by1_PY4 per_capita_exp_all_agnd_by1_PY4 per_capita_exp_all_esrd_by2_PY4 per_capita_exp_all_dis_by2_PY4 per_capita_exp_all_agdu_by2_PY4 per_capita_exp_all_agnd_by2_PY4 per_capita_exp_all_esrd_by3_PY4 per_capita_exp_all_dis_by3_PY4 per_capita_exp_all_agdu_by3_PY4 per_capita_exp_all_agnd_by3_PY4 per_capita_exp_all_esrd_py_PY4 per_capita_exp_all_dis_py_PY4 per_capita_exp_all_agdu_py_PY4 per_capita_exp_all_agnd_py_PY4 per_capita_exp_total_py_PY4 cms_hcc_riskscore_esrd_by1_PY4 cms_hcc_riskscore_dis_by1_PY4 cms_hcc_riskscore_agdu_by1_PY4 cms_hcc_riskscore_agnd_by1_PY4 cms_hcc_riskscore_esrd_by2_PY4 cms_hcc_riskscore_dis_by2_PY4 cms_hcc_riskscore_agdu_by2_PY4 cms_hcc_riskscore_agnd_by2_PY4 cms_hcc_riskscore_esrd_by3_PY4 cms_hcc_riskscore_dis_by3_PY4 cms_hcc_riskscore_agdu_by3_PY4 cms_hcc_riskscore_agnd_by3_PY4 cms_hcc_riskscore_esrd_py_PY4 cms_hcc_riskscore_dis_py_PY4 cms_hcc_riskscore_agdu_py_PY4 cms_hcc_riskscore_agnd_py_PY4 n_ab_year_esrd_by3_PY4 n_ab_year_dis_by3_PY4 n_ab_year_aged_dual_by3_PY4 n_ab_year_aged_nondual_by3_PY4 n_ab_year_py_PY4 n_ab_year_esrd_py_PY4 n_ab_year_dis_py_PY4 n_ab_year_aged_dual_py_PY4 n_ab_year_aged_nondual_py_PY4 n_ben_age_0_64_PY4 n_ben_age_65_74_PY4 n_ben_age_75_84_PY4 n_ben_age_85plus_PY4 n_ben_female_PY4 n_ben_male_PY4 n_ben_race_white_PY4 n_ben_race_black_PY4 n_ben_race_asian_PY4 n_ben_race_hisp_PY4 n_ben_race_native_PY4 n_ben_race_other_PY4 capann_inp_all_PY4 capann_inp_s_trm_PY4 capann_inp_l_trm_PY4 capann_inp_rehab_PY4 capann_inp_psych_PY4 capann_hsp_PY4 capann_snf_PY4 capann_inp_other_PY4 capann_opd_PY4 capann_pb_PY4 capann_ambpay_PY4 capann_hha_PY4 capann_dme_PY4 adm_PY4 adm_s_trm_PY4 adm_l_trm_PY4 adm_rehab_PY4 adm_psych_PY4 chf_adm_PY4 copd_adm_PY4 pneu_adm_PY4 readm_rate_1000_PY4 prov_rate_1000_PY4 p_snf_adm_PY4 p_edv_vis_PY4 p_edv_vis_hosp_PY4 p_ct_vis_PY4 p_mri_vis_PY4 p_em_total_PY4 p_em_pcp_vis_PY4 p_em_sp_vis_PY4 p_nurse_vis_PY4 p_fqhc_rhc_vis_PY4 n_cah_PY4 n_fqhc_PY4 n_rhc_PY4 n_eta_PY4 n_fac_other_PY4 n_pcp_PY4 n_spec_PY4 n_np_PY4 n_pa_PY4 n_cns_PY4
*drop per_capita_exp_all_esrd_by1_PY4 cms_hcc_riskscore_esrd_by1_PY4 per_capita_exp_all_dis_by4_PY1 cms_hcc_riskscore_dis_by1_PY4 per_capita_exp_total_by1_PY4 per_capita_exp_all_esrd_by2_PY4 cms_hcc_riskscore_esrd_by2_PY4 per_capita_exp_all_dis_by2_PY4 cms_hcc_riskscore_dis_by2_PY4 per_capita_exp_total_by2_PY4 per_capita_exp_all_esrd_by3_PY1 cms_hcc_riskscore_esrd_by3_PY1 per_capita_exp_all_dis_by3_PY1 cms_hcc_riskscore_dis_by3_PY1 per_capita_exp_total_by3_PY1 n_ab_year_esrd_by1_PY1 n_ab_year_dis_by1_PY1 n_ab_year_esrd_by2_PY1 n_ab_year_dis_by2_PY1 n_ab_year_esrd_by3_PY1 n_ab_year_dis_by3_PY1 per_capita_exp_all_esrd_by1_PY2 per_capita_exp_all_dis_by1_PY2 per_capita_exp_all_dis_by2_PY2 per_capita_exp_all_agnd_by2_PY2 per_capita_exp_all_esrd_by3_PY2 per_capita_exp_all_dis_by3_PY2 cms_hcc_riskscore_esrd_by1_PY2 cms_hcc_riskscore_dis_by1_PY2 cms_hcc_riskscore_esrd_by2_PY2 cms_hcc_riskscore_dis_by2_PY2 cms_hcc_riskscore_esrd_by3_PY2 cms_hcc_riskscore_dis_by3_PY2 n_ab_year_esrd_by3_PY2 n_ab_year_dis_by3_PY2 per_capita_exp_all_esrd_by1_PY3 per_capita_exp_all_dis_by1_PY3 per_capita_exp_all_esrd_by2_PY3 per_capita_exp_all_dis_by2_PY3 per_capita_exp_all_esrd_by3_PY3 per_capita_exp_all_dis_by3_PY3 cms_hcc_riskscore_esrd_by1_PY3 cms_hcc_riskscore_dis_by1_PY3 cms_hcc_riskscore_esrd_by2_PY3 cms_hcc_riskscore_dis_by2_PY3 cms_hcc_riskscore_esrd_by3_PY3 cms_hcc_riskscore_dis_by3_PY3 n_ab_year_esrd_by3_PY3 n_ab_year_dis_by3_PY3 per_capita_exp_all_esrd_by1_PY4 per_capita_exp_all_dis_by1_PY4 per_capita_exp_all_esrd_by2_PY4 per_capita_exp_all_dis_by2_PY4 per_capita_exp_all_dis_by3_PY4 cms_hcc_riskscore_dis_by1_PY4 cms_hcc_riskscore_esrd_by2_PY4 cms_hcc_riskscore_dis_by2_PY4 cms_hcc_riskscore_esrd_by3_PY4 cms_hcc_riskscore_dis_by3_PY4 n_ab_year_esrd_by3_PY4 n_ab_year_dis_by3_PY4  // dropping to make room provisionally (BU 11/2017)

***** BU: 11/2017: Name changes to facilitate merging
replace aconame_cms = "Alexian Brothers Accountable Care Organization" if aconame_cms=="Alexian Brothers Accountable Care Organization, LLC"
replace aconame_cms = "Chicago Health System ACO, LLC" if aconame_cms=="CHS ACO"

*****************
*label var earnedsavingsowelosses_PY4 "Earned Shared Savings Payments/ Owe"

replace aconame_cms = "University of Michigan" if aconame_cms=="POM ACO"


drop _merge


saveold "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/MSSP Quality and Savings_innovators_version.dta", replace

************************
********TESTING*********
************************

*Checking there are no duplicate ACO names after merge - manual check*
*ACO 2015 start date list - https://www.cms.gov/Medicare/Medicare-Fee-for-Service-Payment/sharedsavingsprogram/Downloads/MSSP-ACOs-2015-Starters.pdf*
order *, sequential
*order aconame_cms start_date _merge
sort aconame_cms

*RESULTS*
*Cornerstone Health Enablement Strategic Solutions, LLC - not matching, present in both files, names need to be checked in master and using*
*********REPAIRED*********

*All Mercy ACOs verified to be separate in MSSP 2015 results*

*ACO Pushbacks - check for reporting failures*
*South Texas Care Connect - 2012 start, only appears in PY3
*southtexascareconnect.com/ACO/ACOCompliancePlan.aspx - Website redirects to Baptist Integrated Physician Partners, has MSSP BHS Accountable Care, LLC*
*BHS Accountable Care has 2 years MSSP data, drops out in PY3 - same org? Name change?

*North Jersey ACO, LLC - 2013 start, only appears in PY3
*http://67.225.251.32/files/ACO-Public-Reporting.pdf
*Name doesn't exist in earlier files

*CHS ACO - 2012 start, only appears in PY3*
*Seems like Chicago Health System ACO, LLC is referred to as CHS ACO in results, change name to reflect current*
*********REPAIRED*********

*HCP ACO California, LLC - 2014 start, only appears in PY2*
*Looks like a typo - should be merged with HCO ACO California, LLC*
*********REPAIRED*********

*Renown Accountable Care - 2014 start, only appears in PY2*
*https://www.renown.org/about-us/accountable-care/public-reporting/
*In 2014, formerly R TotalHealth, LLC, change name to reflect current*
*********REPAIRED*********

*Baroma ACOs all look very confusing, names need to be double-checked.
*All of these names did not exist in previous years - look like they're all renames*
*BAROMA Heatlhcare Holdings - 2014 start, only appears in PY2*
*Baroma Healthcare, LLC - 2014 start, only appears in PY2*
*Baroma Healthcare International, LLC - 2013 start, only appears in PY3*
*********REPAIRED*********

**************************
********QUESTIONS*********
**************************

*Q: How above do we determine which ACOs need to be pushed back a year? Based on start date?
*Related Q: Should all ACOs w/ 2015 start date be pushed to PY1? Individual org vs. ACO program performance year?





*Import CSV from CMS website
*Website: https://www.cms.gov/research-statistics-data-and-systems/downloadable-public-use-files/sspaco/overview.html

foreach year in PY1 PY2 PY3 PY4 {

	clear
	set more off
	import excel using "/Volumes/NSACO/NSACO Data Master/CMS/Data files/CMS raw data/ACO.SSP.PUF.`year'.xlsx", firstrow case(lower) clear
	
	capture rename ïaco_num_PY3 aco_num_PY3  //added because csv has aco_num_PY3 named as ïaco_num_PY3 [note strange character "ï"]	 BU (01/23/2017)
	*Rename aco name to standard format across all extra CMS files
	capture rename initial_start_date start_date  // (BU 11/2017 to account for different variable name in PY4 data
	rename aco_name aconame_cms
	
	*Format start date
		format start_date %td
	
	*Eliminate end spaces in ACO Name
	replace aconame_cms = trim(aconame_cms)
	
	
	****BU (11/2017)
	
replace aconame_cms ="CHS ACO" if aconame_cms=="Chicago Health System ACO, LLC"
	
 
*replace aco_num = "A09903" if aconame_cms == "JFK Health ACO"
replace aco_num ="A71489" if aconame_cms == "Barnabas Health Care Network"
replace aco_num ="A36859" if aconame_cms =="Baroma Healthcare International, LLC" 
*replace aco_num = "A09282" if aconame_cms == "Baroma Healthcare, LLC"  //see comments below re Baroma identifiers ; therefore this line commented out
*replace aconame_cms = "BAROMA Healthcare Holdings" if aco_num=="A92615" // see comments below re Baroma identifiers; therefore this line commented out
	
	*Matching ACO Names to CMS format 
	
	
	

	replace aconame_cms="Atlantic ACO" if aconame_cms=="AHS ACO, LLC"
	*https://www.cms.gov/Medicare/Medicare-Fee-for-Service-Payment/sharedsavingsprogram/Downloads/ACO-Information-List.pdf

	replace aconame_cms="Arizona Priority Care Plus" if aconame_cms=="AzPCP-ACO, A Medical Corporation, PC"
	*https://www.cms.gov/Medicare/Medicare-Fee-for-Service-Payment/sharedsavingsprogram/Downloads/ACO-Information-List.pdf
	*http://www.az-pcp.com/content/pdfs/care_center_mdjob_posting.pdf

	replace aconame_cms="Good Help ACO" if aconame_cms=="Bon Secours Good Helpcare LLC"
	*http://goodhelpaco.org/aco-public-reporting/

	replace aconame_cms="Doctors Connected" if aconame_cms=="Carilion Clinic Medicare Shared Savings Company, LLC"
	*http://www.doctorsconnected.org/faq.html ("Doctors Connected® is a registered trademark of Carilion Clinic Medicare Shared Savings Co., LLC.")
	*Somewhat sketchier: http://www.buzzfile.com/business/Doctors-Connected-855-336-9005

	replace aconame_cms="NH Accountable Care Partners" if aconame_cms=="Concord Elliot ACO LLC"
	*http://www.concordhospital.org/news/2014-news/wentworth-douglass-hospital-southern-new-hampshire-health-system/

	replace aconame_cms="UnityPoint Health Partners" if aconame_cms=="Iowa Health Accountable Care, L.C."
	*https://www.unitypoint.org/public-reporting-information.aspx

	replace aconame_cms="Millennium Accountable Care Organization" if aconame_cms=="ProCare Med, LLC"
	*http://www.millenniumaccountablecare.com/public-reporting/

	replace aconame_cms="New Health Collaborative" if aconame_cms=="Summa Accountable Care Organization"
	*http://www.summahealth.org/aco

	replace aconame_cms="Orange Accountable Care" if aconame_cms=="ACO Health Partners, LLC"
	*http://www.orangehealthaco.net/About.aspx

	replace aconame_cms="VirtuaCare" if aconame_cms=="Summit Health-Virtua, Inc."
	*https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&ved=0CCAQFjAAahUKEwjDjoHC6bXHAhXBPT4KHTJcASQ&url=https%3A%2F%2Fwww.virtua.org%2F-%2Fmedia%2FFiles%2FVirtua%2520Enterprise%2Fpdf%2Faco%2Faco-public-reporting-10-16-14.ashx%3Fla%3Den&ei=Z9HUVYO_GcH7-AGyuIWgAg&usg=AFQjCNGLESNu_jrRQ50YDXffN3qLxKZSLA&bvm=bv.99804247,d.cWw&cad=rja
	*http://www.bizjournals.com/philadelphia/news/2013/01/10/summit-health-virtua-accepted-by-hhs.html

	replace aconame_cms="Collaborative Health ACO" if aconame_cms=="Total Accountable Care Organization"
	*http://gojunto.com/aco-database/4445/total-accountable-care-organization-dba-collaborative-health-aco/
	*https://thinkhomecare.wordpress.com/2013/01/14/acos-expanded-in-massachusetts/

	replace aconame_cms="Community Health Network" if aconame_cms=="Triple Aim Accountable Care Organization"
	*https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=2&cad=rja&uact=8&ved=0CCEQFjABahUKEwikmZDm67XHAhWMGT4KHRjmDZE&url=https%3A%2F%2Fwww.dacbond.com%2FGetContent%3Fid%3D0900bbc780158151&ei=zNPUVaSDAoyz-AGYzLeICQ&usg=AFQjCNG4IRXt0YghQCsnCh7_ysbhMmzzkA
	*See page 5

	replace aconame_cms="Physicians Accountable Care Organization, LLC" if aconame_cms=="Accountable Care Coalition of New Mexico, LLC"
	*http://www.bloomberg.com/research/stocks/private/snapshot.asp?privcapId=278910858

	replace aconame_cms="Physicians ACO" if aconame_cms=="Physicians ACO, LLC" & aco_num !="A03682"
	*http://physiciansaco.net/organization/

	replace aconame_cms="UCLA Faculty Practice Group" if aconame_cms=="Regents of the University of California"
	*https://www.uclahealth.org/pages/patients/accountable-care-organization-aco.aspx

	replace aconame_cms="SEMAC" if aconame_cms=="Southeast Michigan Accountable Care, Inc."
	*http://www.semacaco.com/

	replace aconame_cms="Mercy-CR/UI Health Care Accountable Care Organization" if aconame_cms=="University of Iowa Affiliated Health Providers, LC"
	*https://www.healthcare.uiowa.edu/UIHCPortal/initiatives.html
	*http://www.uihealthcare.org/newsarticle.aspx?id=232593

	*Accountable Care Networks of Florida, New Jersey, Texas part of Walgreens programs
	*http://www.modernhealthcare.com/article/20141230/NEWS/312309975
	*http://www.pharmacytimes.com/publications/directions-in-pharmacy/2015/march2015/walgreens-severs-ties-with-acos
	*http://www.beckershospitalreview.com/hospital-physician-relationships/walgreens-strategy-behind-aco-participation.html
	*http://investor.walgreensbootsalliance.com/secfiling.cfm?filingid=104207-13-104&cik=104207
	*http://www.hpae.org/newsroom/articles/20130110_acosnj

	replace aconame_cms="Advocare Well Network" if aconame_cms=="Accountable Care Network of New Jersey, LLC"
	*http://www.accountablecarenj.org/organization.html

	replace aconame_cms="Diagnostic Clinic Walgreens Well Network" if aconame_cms=="Accountable Care Network of Florida, LLC"
	*Data in this dataset matches data in website below for Diagnostic Clinic Walgreens Well Network
	*https://www.pulsepilot.com/directory/Diagnostic-Clinic-Walgreens-Well-Network

	replace aconame_cms="Scott & White Healthcare Walgreens Well Network, LLC" if aconame_cms=="Accountable Care Network of Texas, LLC"

	replace aconame_cms="Hackensack Alliance ACO" if aconame_cms=="Hackensack Physician-Hospital Alliance ACO, LLC"

	replace aconame_cms="Cape Cod Health Network ACO" if aconame_cms=="Cape Cod Health Network ACO, LLC"

	replace aconame_cms="SERPA-ACO" if aconame_cms=="SERPA ACO, LLC"

	replace aconame_cms="Keystone ACO" if aconame_cms=="Keystone Accountable Care Organization, LLC"

	replace aconame_cms="KCMPA" if aconame_cms=="KCMPA-ACO, LLC"

	replace aconame_cms="Franciscan Union ACO" if aconame_cms=="Franciscan Union Hospital ACO, LLC"

	replace aconame_cms="AAMC Collaborative Care Network, LLC" if aconame_cms=="AAMC Collaborative Care Network"

	replace aconame_cms="Cedars-Sinai Medical Care Foundation" if aconame_cms=="Cedars-Sinai Accountable Care, LLC"

	replace aconame_cms="American Health Network of Ohio PC" if aconame_cms=="American Health Network of Ohio Care Organization, LLC"
	*https://www.ahni.com/Medicare/Accountable+Care+Organization/Public+Reporting/Ohio.html

	replace aconame_cms="Balance ACO" if aconame_cms=="Balance Accountable Care Network"
	*http://www.balanceaco.com/Balance%20ACO%20Public%20Information.pdf

	*replace aconame_cms="BAROMA Health Partners" if aconame_cms=="Baroma Healthcare International"
	*See bottom right-hand corner of this page:
	*http://www.baromahc.com/bhp_index.html
	*BUT the quality measures reported for Baroma Healthcare International match the quality measure data for BAROMA Health Partners:
	*http://www.baromahc.com/bhp_A1419_pub.html

	replace aconame_cms="CCACO" if aconame_cms=="Chinese Community Accountable Care Organization, Inc." //From MSSP list. Same org (double-checked with salesforce)
	*http://www.ccaco.org/

	replace aconame_cms="Cambridge Health Alliance" if aconame_cms=="Cambridge Public Health Commission"
	*^According to http://www.hoovers.com/company-information/cs/company-profile.Cambridge_Public_Health_Commission.58d2db91d97269c1.html
	*http://www.mass.gov/anf/docs/hpc/regs-and-notices/cambridge-public-health-commission.pdf
	*^See Q11

	replace aconame_cms="Central Florida Physicians Trust" if aconame_cms=="Central Florida Physicians Trust, LLC" //MSSP list doesn't include the LLC
	*http://www.cflphysicianstrust.org/index.php?id=aco

	replace aconame_cms="Greater Baltimore Health Alliance" if aconame_cms=="Greater Baltimore Health Alliance Physicians, LLC" //MSSP list doesn't include Physicians. Same org (cross-checked with Salesforce)
	*http://gbha.org/about

	replace aconame_cms="Heartland" if aconame_cms=="Heartland Regional Medical Center" //MSSP lists as "Heartland." NOTE: Name change. Now Mosaic Life Care
	*^According to https://www.mymosaiclifecare.org/Main/About-Mosaic-Life-Care/Media-and-Public-Relations/Press-Releases/HRMC-aco-saves-medicare-853-million-during-first-year-of-operations/
	*http://www.commonwealthfund.org/publications/newsletters/quality-matters/2014/june-july/profile-heartland

	replace aconame_cms="Indiana Lakes ACO" if aconame_cms=="Indiana Lakes ACO, LLC" //MSSP list doesn't include LLC
	/*http://www.ismanet.org/news/RSSArticle691.aspx#.VdTR8edifiA
	Compared to
	http://indianalakesaco.com/
	*/

	replace aconame_cms="John Muir Health Medicare ACO" if aconame_cms=="John Muir Physician Network" //Name used by MSSP. Cross-checked with Salesforce
	*http://www.johnmuirhealth.com/about-john-muir-health/medicare-aco.html

	replace aconame_cms="Medical Mall ACO" if aconame_cms=="Medical Mall Services of Mississippi" //Name used by MSSP. Cross-checked with Salesforce
	*http://www.medicalmallservicesms.com/who-we-are/about-us.html

	replace aconame_cms="Medical Practitioners For Affordable Care, LLC" if aconame_cms=="Medical Practitioners for Affordable Care, LLC" //Cap in MSSP

	replace aconame_cms="Meridian Health Systems ACO Corporation" if aconame_cms=="Meridian Holdings, Inc." //Name used by MSSP. Cross-checked with Salesforce
	*http://www.mhsaco.us/

	replace aconame_cms="Morehouse Choice ACO-ES" if aconame_cms=="Morehouse Choice Accountable Care Organization and Education System, Inc." //Name used by MSSP. Cross-checked with Salesforce
	*http://morehousechoiceacoes.org/

	replace aconame_cms="POM ACO" if aconame_cms=="Physician Organization of Michigan ACO, LLC" //Name used by MSSP. Cross-checked with Salesforce
	*http://pom-aco.com/

	replace aconame_cms="Quality Independent Physicians, LLC" if aconame_cms=="Quality Independent Physicians" //MSSP uses LLC
	*http://www.qipllc.com/

	replace aconame_cms="Reliance Health Network" if aconame_cms=="Reliance Healthcare Management Solutions, LLC" //Name used by MSSP. Cross-checked with Salesforce
	/*
	http://www.hipaaspace.com/Medical_Billing/Coding/NPI/Codes/NPI_1366713612.aspx
	Compare to
	http://www.reliancehms.com/about-us/general-information/
	*/

	replace aconame_cms="The Polyclinic" if aconame_cms=="Polyclinic Management Services Company" //Name used by MSSP. Cross-checked with Salesforce

	replace aconame_cms="Triad HealthCare Network" if aconame_cms=="Triad Healthcare Network, LLC" //Name used by MSSP. Cross-checked with Salesforce

	replace aconame_cms="University Hospitals Coordinated Care Organization" if aconame_cms=="University Hospitals Coordinated Care" //Name used by MSSP. Cross-checked with Salesforce
	*http://www.uhhospitals.org/about/accountable-care-organization/medicare-aco/uh-coordinated-care-organization

	replace aconame_cms="Wellmont Integrated Network" if aconame_cms=="Wellmont Integrated Network, LLC" //LLC not used in Salesforce. Neither in MSSP list
	*http://www.tennesseecorps.com/corp/177833.html

	replace aconame_cms="Winchester Community ACO" if aconame_cms=="Winchester Community Accountable Care Organization, Inc." //Name used by MSSP and Salesforce
	*http://www.winchesterhospital.org/our-services/medical-care/departments-centers/winaco

	replace aconame_cms="Yavapai Accountable Care, LLC" if aconame_cms=="Yavapai Accountable Care" //Name used by MSSP. Cross-checked with Salesforce
	*http://www.yavapaiaccountablecare.com/Yavapai%20Accountable%20Care%20Website%20Disclosure.pdf

	replace aconame_cms="Yuma Connected Community" if aconame_cms=="Yuma Accountable Care Organization, LLC" //Name used in Salesforce (not in MSSP list)
	*^According to http://www.yumaconnectedcommunity.com/about.aspx

	replace aconame_cms="Dean Clinic and St. Mary's Hospital ACO" if aconame_cms=="Dean Clinic and St. Mary's Hospital Accountable Care Organization, LLC" //Name used in linking key. Not in MSSP list
	*http://www.modernhealthcare.com/article/20140926/NEWS/309269939

	replace aconame_cms="Primary Partners" if aconame_cms=="Primary Partners ACIP LLC"
	*^According to http://primarypartners.org/public-reporting/
	
	***BU 11/2017: adjust for Renown name change  
	replace aconame_cms = "R TotalHealth, LLC" if aconame_cms == "Renown Accountable Care, LLC" 	
	
	**** Bu 11/2017: rename to facilitate merging
	replace aconame_cms = "Chicago Health System ACO, LLC" if aconame_cms =="CHS ACO"
	
	replace aconame_cms="University of Michigan" if aconame_cms=="POM ACO"  //only for this innovators project; switch back for regular merge
	
		replace aconame_cms="HCP ACO California, LLC" if aconame_cms=="HCP ACO CA LLC"	
	
	*Capitalization
	replace aconame_cms="Maryland Accountable Care Organization of Western MD LLC" if aconame_cms=="MARYLAND ACCOUNTABLE CARE ORGANIZATION OF WESTERN MD LLC"
	replace aconame_cms="Maryland Accountable Care Organization of Eastern Shore LLC" if aconame_cms=="MARYLAND ACCOUNTABLE CARE ORGANIZATION OF EASTERN SHORE LLC"
	replace aconame_cms="Golden Life Accountable Care Organization (ACO)" if aconame_cms=="GOLDEN LIFE HEALTHCARE LLC"
	replace aconame_cms="APCN-ACO, A Medical Professional Corporation" if aconame_cms=="APCN-ACO, A MEDICAL PROFESSIONAL CORPORATION"
	replace aconame_cms="Nature Coast ACO LLC" if aconame_cms=="NATURE COAST ACO LLC"
	replace aconame_cms="MCM Accountable Care Organization, LLC" if aconame_cms=="MCM ACCOUNTABLE CARE ORGANIZATION, LLC"
	replace aconame_cms="Hartford Healthcare Accountable Care Organization, Inc." if aconame_cms=="HARTFORD HEALTHCARE ACCOUNTABLE CARE ORGANIZATION, INC."
	replace aconame_cms="Accountable Care Clinical Services, PC" if aconame_cms=="ACCOUNTABLE CARE CLINICAL SERVICES, PC"

	rename * *_`year'
	
	
	capture rename n_ab_year_py_PY3 n_ab_year_PY3
	capture rename n_ab_year_esrd_py_PY3 n_ab_year_esrd_PY3
	capture rename n_ab_year_dis_py_PY3 n_ab_year_dis_PY3
	capture rename n_ab_year_aged_dual_py_PY3 n_ab_year_aged_dual_PY3
	capture rename n_ab_year_aged_nondual_py_PY3 n_ab_year_aged_nondual_PY3	
	*BU 11/2017: adding PY4 renames
	capture rename n_ab_year_py_PY4 n_ab_year_PY4
	capture rename n_ab_year_esrd_py_PY4 n_ab_year_esrd_PY4
	capture rename n_ab_year_dis_py_PY4 n_ab_year_dis_PY4
	capture rename n_ab_year_aged_dual_py_PY4 n_ab_year_aged_dual_PY4
	capture rename n_ab_year_aged_nondual_py_PY4 n_ab_year_aged_nondual_PY4	
		
	********
	*********
	********THIS SECTION IN PROGRESS
	*********BU: 11/2017: attempting to rename as many CMS vars to standardize and make room
	capture rename n_ab_year`year' n_ab`year'
	capture rename n_ab_year_agdu_by1`year' n_ab_year_aged_dual_by1`year'
	capture rename n_ab_year_agnd_by1`year' n_ab_year_aged_nondual_by1`year'
	capture rename n_ab_year_agdu_by2`year' n_ab_year_aged_dual_by2`year'
	capture rename n_ab_year_agnd_by2`year' n_ab_year_aged_nondual_by2`year'
	capture rename n_ab_year_agdu_by3`year' n_ab_year_aged_dual_by3`year'
	capture rename n_ab_year_agnd_by3`year' n_ab_year_aged_nondual_by3`year'
	capture rename per_capita_exp_all_esrd_py`year' per_capita_exp_all_esrd`year'	
	capture rename per_capita_exp_all_dis_py`year'  per_capita_exp_all_dis`year' 	
	capture rename per_capita_exp_total_py`year' per_capita_exp_total`year'	
	capture rename per_capita_exp_all_esrd_py`year'  per_capita_exp_all_esrd`year' 
	capture rename cms_hcc_riskscore_esrd_py`year' 	cms_hcc_riskscore_esrd`year'

	
	
	
	*********
	*********
	*********
	
	
	capture drop track*  // added capture to account for different name in PY4
	capture drop 
	capture rename ïaconum_PY3 aconum_PY3
	rename aconame_cms_`year' aconame_cms
	rename aco_num_`year' aco_num
	rename start_date_`year' start_date
	
	*Destring qualscore for PY2
	capture replace qualscore_PY2=".p" if qualscore_PY2=="P4R"
	capture destring qualscore_PY2, replace
	
	capture replace qualscore_PY2 = 100 * qualscore_PY2 if !missing(qualscore_PY2)  //This will standardize qualscores to be from 0-100 instead of 0 to 1; (BU 01/25/17)
	
 
	
	
	saveold "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/Final.ACO.SSP.PUF.`year'.dta", replace
}


set more off

use "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/Final.ACO.SSP.PUF.PY1.dta", clear
gen earnsaveloss_PY1 = earnshrsavings_PY1
replace earnsaveloss_PY1= owelosses_PY1 if !missing(owelosses_PY1)

merge 1:1 aco_num using "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/Final.ACO.SSP.PUF.PY2.dta"

drop _merge

merge 1:1 aco_num using "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/Final.ACO.SSP.PUF.PY3.dta"

drop _merge

merge 1:1 aco_num using "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/Final.ACO.SSP.PUF.PY4.dta" // added (11/2017 BU for PY4 data)
drop _merge
*Replace y1 missings with y2 data if y2 starter

	*variables new to y1 or y2
	
		gen sav_rate_PY1=.
		*gen earnsaveloss_PY1=.
		gen updatedbnchmk_PY1=.
		gen histbnchmk_PY1=.
		gen adv_pay_recoup_PY1=.
		gen capann_opd_PY1=.
		gen gensaveloss_PY1=.
		gen int_pmt_PY2=.
		gen minlossperc_PY2=.
		gen earnshrsavings_PY2=.
		gen owelosses_PY2=.
		gen per_capita_exp_all_esrd_PY2=.
		gen per_capita_exp_all_dis_PY2=.
		gen per_capita_exp_all_agdu_PY2=.
		gen per_capita_exp_all_agnd_PY2=.
		gen gensaveloss_PY2=.
	
	*variables new to y3
	*AJM - figure out some way to determine that, add here
	
		*All exist in PY2 and PY3 - generating for PY1*
		foreach benchmark in by1 by2 by3 py {
			foreach condition in esrd dis agdu agnd {
				gen per_capita_exp_all_`condition'_`benchmark'_PY1=.
				gen cms_hcc_riskscore_`condition'_`benchmark'_PY1=.
			}
			gen per_capita_exp_total_`benchmark'_PY1=.
		}
		
		*All exist in PY2 and PY3 - generating for PY1*
		foreach benchmark in by1 by2 by3 {
			foreach condition in esrd dis agdu agnd {
				gen n_ab_year_`condition'_`benchmark'_PY1=.
			}
			gen n_ab_year_aged_dual_`benchmark'_PY1=.
			gen n_ab_year_aged_nondual_`benchmark'_PY1=.
		}

	foreach varstub in adv_pay n_ab sav_rate minsavperc bnchmkminexp earnsaveloss qualscore updatedbnchmk histbnchmk abtotbnchmk abtotexp adv_pay_amt adv_pay_recoup qualperfshare finalsharerate per_capita_exp_all_esrd_by1 per_capita_exp_all_dis_by1 per_capita_exp_all_agdu_by1 per_capita_exp_all_agnd_by1 per_capita_exp_all_esrd_by2 per_capita_exp_all_dis_by2 per_capita_exp_all_agdu_by2 per_capita_exp_all_agnd_by2 per_capita_exp_all_esrd_by3 per_capita_exp_all_dis_by3 per_capita_exp_all_agdu_by3 per_capita_exp_all_agnd_by3 per_capita_exp_all_esrd_py per_capita_exp_all_dis_py per_capita_exp_all_agdu_py per_capita_exp_all_agnd_py per_capita_exp_total_py cms_hcc_riskscore_esrd_by1 cms_hcc_riskscore_dis_by1 cms_hcc_riskscore_agdu_by1 cms_hcc_riskscore_agnd_by1 cms_hcc_riskscore_esrd_by2 cms_hcc_riskscore_dis_by2 cms_hcc_riskscore_agdu_by2 cms_hcc_riskscore_agnd_by2 cms_hcc_riskscore_esrd_by3 cms_hcc_riskscore_dis_by3 cms_hcc_riskscore_agdu_by3 cms_hcc_riskscore_agnd_by3 cms_hcc_riskscore_esrd_py cms_hcc_riskscore_dis_py cms_hcc_riskscore_agdu_py cms_hcc_riskscore_agnd_py n_ab_year_esrd_by3 n_ab_year_dis_by3 n_ab_year_aged_dual_by3 n_ab_year_aged_nondual_by3 n_ab_year n_ab_year_esrd n_ab_year_dis n_ab_year_aged_dual n_ab_year_aged_nondual n_ben_age_0_64 n_ben_age_65_74 n_ben_age_75_84 n_ben_age_85plus n_ben_female n_ben_male n_ben_race_white n_ben_race_black n_ben_race_asian n_ben_race_hisp n_ben_race_native n_ben_race_other capann_inp_all capann_inp_s_trm capann_inp_l_trm capann_inp_rehab capann_inp_psych capann_hsp capann_snf capann_inp_other capann_opd capann_pb capann_ambpay capann_hha capann_dme adm adm_s_trm adm_l_trm adm_rehab adm_psych chf_adm copd_adm pneu_adm readm_rate_1000 prov_rate_1000 p_snf_adm p_edv_vis p_edv_vis_hosp p_ct_vis p_mri_vis p_em_total p_em_pcp_vis p_em_sp_vis p_nurse_vis p_fqhc_rhc_vis n_cah n_fqhc n_rhc n_eta n_fac_other n_pcp n_spec n_np n_pa n_cns {
		*Don't do the replacement for Pioneer switchers (want their data to still be _PY2)
		replace `varstub'_PY1=`varstub'_PY2 if (start_date==19724 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553", "A14417"))
		replace `varstub'_PY2=. if (start_date==19724 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553", "A14417"))
		replace `varstub'_PY1=`varstub'_PY3 if (start_date==20089 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553", "A14417"))  //Added to account for 2015 data (BU 01/19/2017)
		replace `varstub'_PY3=. if (start_date==20089 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553", "A14417"))    //Added to account for 2015 data (BU 01/19/2017)
		**adding for PY4 (BU 11/2017)
		 replace `varstub'_PY1=`varstub'_PY4 if (start_date==20454 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553", "A14417"))
		 replace `varstub'_PY4=. if (start_date==20454 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A14417"))
		 replace `varstub'_PY2=`varstub'_PY4 if (start_date==20089 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553", "A14417"))		
		 replace `varstub'_PY4=. if (start_date==20089 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553", "A14417"))	
		 /*replace `varstub'_PY3=`varstub'_PY4 if (start_date==19359 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553"))
		 replace `varstub'_PY4= . if (start_date==19359 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553"))	*/
		 
		 
		 
		 }
	*rename n_ab_year_py_PY3 n_ab_year_PY3
	*rename n_ab_year_esrd_py_PY3 n_ab_year_esrd_PY3
	*rename n_ab_year_dis_py_PY3 n_ab_year_dis_PY3
	*rename n_ab_year_aged_dual_py_PY3 n_ab_year_aged_dual_PY3
	*rename n_ab_year_aged_nondual_py_PY3 n_ab_year_aged_nondual_PY3
*/
*AJM - move PY3 to PY2 for PY2 starters (replicating above)
	foreach varstub in adv_pay n_ab sav_rate minsavperc bnchmkminexp earnsaveloss qualscore updatedbnchmk histbnchmk abtotbnchmk abtotexp adv_pay_amt adv_pay_recoup qualperfshare finalsharerate per_capita_exp_all_esrd_by1 per_capita_exp_all_dis_by1 per_capita_exp_all_agdu_by1 per_capita_exp_all_agnd_by1 per_capita_exp_all_esrd_by2 per_capita_exp_all_dis_by2 per_capita_exp_all_agdu_by2 per_capita_exp_all_agnd_by2 per_capita_exp_all_esrd_by3 per_capita_exp_all_dis_by3 per_capita_exp_all_agdu_by3 per_capita_exp_all_agnd_by3 per_capita_exp_all_esrd_py per_capita_exp_all_dis_py per_capita_exp_all_agdu_py per_capita_exp_all_agnd_py per_capita_exp_total_py cms_hcc_riskscore_esrd_by1 cms_hcc_riskscore_dis_by1 cms_hcc_riskscore_agdu_by1 cms_hcc_riskscore_agnd_by1 cms_hcc_riskscore_esrd_by2 cms_hcc_riskscore_dis_by2 cms_hcc_riskscore_agdu_by2 cms_hcc_riskscore_agnd_by2 cms_hcc_riskscore_esrd_by3 cms_hcc_riskscore_dis_by3 cms_hcc_riskscore_agdu_by3 cms_hcc_riskscore_agnd_by3 cms_hcc_riskscore_esrd_py cms_hcc_riskscore_dis_py cms_hcc_riskscore_agdu_py cms_hcc_riskscore_agnd_py n_ab_year_esrd_by3 n_ab_year_dis_by3 n_ab_year_aged_dual_by3 n_ab_year_aged_nondual_by3 n_ab_year n_ab_year_esrd n_ab_year_dis n_ab_year_aged_dual n_ab_year_aged_nondual n_ben_age_0_64 n_ben_age_65_74 n_ben_age_75_84 n_ben_age_85plus n_ben_female n_ben_male n_ben_race_white n_ben_race_black n_ben_race_asian n_ben_race_hisp n_ben_race_native n_ben_race_other capann_inp_all capann_inp_s_trm capann_inp_l_trm capann_inp_rehab capann_inp_psych capann_hsp capann_snf capann_inp_other capann_opd capann_pb capann_ambpay capann_hha capann_dme adm adm_s_trm adm_l_trm adm_rehab adm_psych chf_adm copd_adm pneu_adm readm_rate_1000 prov_rate_1000 p_snf_adm p_edv_vis p_edv_vis_hosp p_ct_vis p_mri_vis p_em_total p_em_pcp_vis p_em_sp_vis p_nurse_vis p_fqhc_rhc_vis n_cah n_fqhc n_rhc n_eta n_fac_other n_pcp n_spec n_np n_pa n_cns {
		/*replace `varstub'_PY1=`varstub'_PY2 if (start_date==19724 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553", "A55185"))
		replace `varstub'_PY2="." if (start_date==19724 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553",  "A55185"))*/		
		replace `varstub'_PY2=`varstub'_PY3 if (start_date==19724 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553", "A55185", "A14417"))
		replace `varstub'_PY3=. if (start_date==19724 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553", "A55185", "A14417"))
		replace `varstub'_PY1=`varstub'_PY3 if (start_date==20089 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553", "A55185", "A14417")) //Added to account for 2015 data (BU 01/19/2017)
		replace `varstub'_PY3=. if (start_date==20089 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553", "A55185", "A14417")) //Added to account for 2015 data (BU 01/19/2017)		
	**adding for PY4 (BU 11/2017)
	 
		 replace `varstub'_PY3=`varstub'_PY4 if (start_date==19724 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553", "A55185", "A14417"))
		 replace `varstub'_PY4= . if (start_date==19724 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553", "A55185", "A14417"))   
		 gen `varstub'_PY5 = `varstub'_PY4 if aco_num=="A88553"  //accounting for Franciscan Alliance switched to MSSP in 2015		 
		 replace `varstub'_PY4 = `varstub'_PY3 if aco_num=="A88553"  //accounting for Franciscan Alliance switched to MSSP in 2015
		 replace `varstub'_PY3=. if aco_num=="A88553"  // //accounting for Franciscan Alliance switched to MSSP in 2015
		 *replace `varstub'_PY5=`varstub'_PY4 if aco_num=="A88553"
		 /*replace `varstub'_PY5=`varstub'_PY4 if aco_num=="A55185"
		 replace `varstub'_PY4=`varstub'_PY3 if aco_num=="A55185"
		 replace `varstub'_PY3=`varstub'_PY2 if aco_num=="A55185"
		 replace `varstub'_PY2=`varstub'_PY1 if aco_num=="A55185"*/
		 replace `varstub'_PY1=. if aco_num=="A55185" 
		 
	}
	
	gen aco_state_PY1="."
	foreach varstub in aco_state {
		replace `varstub'_PY1=`varstub'_PY2 if (start_date==19724 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553", "A55185", "A14417"))
		replace `varstub'_PY2="." if (start_date==19724 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553",  "A55185", "A14417"))
		*AJM - repeating for PY3
		replace `varstub'_PY2=`varstub'_PY3 if (start_date==19724 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553", "A55185", "A14417"))
		replace `varstub'_PY3="." if (start_date==19724 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553", "A55185", "A14417"))
	*	replace `varstub'_PY1="Data not available until 2014" if (start_date!=19724 & !inlist(aco_num,"A71307","A07620","A13467","A73981"))  //commenting out this line due to addition of 2015 data and 2 following lines (BU 01/19/2017)
		replace `varstub'_PY1=`varstub'_PY3 if (start_date==20089 & !inlist(aco_num,"A71307","A07620","A13467","A73981","A88553", "A88553", "A55185", "A14417"))  //Added to account for 2015 data (BU 01/19/2017)
		replace `varstub'_PY3="." if (start_date==20089 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553", "A88553", "A55185", "A14417"))	  //Added to account for 2015 data (BU 01/19/2017)
		**adding for PY4 (BU 11/2017)
		 replace `varstub'_PY1=`varstub'_PY4 if (start_date==20454 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553", "A55185", "A14417"))
		 replace `varstub'_PY4="." if (start_date==20454 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553", "A14417"))
		 replace `varstub'_PY2=`varstub'_PY4 if (start_date==20089 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553", "A55185", "A14417"))		
		 replace `varstub'_PY4="." if (start_date==20089 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553", "A55185", "A14417"))	
		 
		 replace `varstub'_PY3=`varstub'_PY4 if (start_date==19724 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553", "A55185", "A14417"))
		 replace `varstub'_PY4="." if (start_date==19724 & !inlist(aco_num,"A71307","A07620","A13467","A73981", "A88553", "A55185", "A14417"))  		 
			}
			
	
	*ACOs new in PY3*	
*start_date==20089 = Jan 1, 2015*
list aconame_cms if start_date==20089

	*Note for future: Need to check merge. Sort by aconame_cms and double-check that all merged properly. Edit names in cleaning files as necessary
	*ALL should match. Sometimes names are very different. Look for _____ dba ______ (a good resource is Googling the name folllowed by "public reporting")
		
		*Need to use start date as well because some ACOs have the same name (Mercy ACO)
		*Need to use baromaident since two Baroma Health Partners have same start date
		
*Note for future: Need to check merge. Sort by aconame_cms and double-check that all merged properly. Edit names in cleaning files as necessary
				
				*The following mismatches are okay:
					
					*If merge3==2 (using only) and start_date=="01/01/2014" since the ACO SSP PUF and MSSP y1 data are from 2013
					
					*If merge3==1 (master only) and ACO dropped out of MSSP program between 2013 and 2014
					*See "List of dropped MSSP ACOs" for details
	
gen aconame_cms_original = aconame_cms 
	
	gen baromaident=1 if aco_num=="A09282"
		replace baromaident=2 if aco_num=="A92615"
		capture lab var baromaident "Baroma Health Partners identifier for merging"
		capture lab define baromaidentL 1 "Florida" 2 "Texas,  Louisiana"
		capture lab val baromaident baromaidentL
		
	replace aconame_cms="ACMG" if aconame_cms=="Accountable Care Medical Group of Florida, Inc."
	replace aconame_cms="Allegiance ACO" if aconame_cms=="Allegiance MSO LLC"
	replace aconame_cms="Antelope Valley ACO" if aconame_cms=="Antelope Valley ACO, Inc"
	replace aconame_cms="Baroma Health Partners" if aconame_cms=="BAROMA Healthcare Holdings"
	replace aconame_cms="Baroma Health Partners" if aconame_cms=="Baroma Healthcare, LLC"
	replace aconame_cms="Bayview Physicians Group" if aconame_cms=="Bayview Physician Services, PC"
	replace aconame_cms="Delmarva Health Network" if aconame_cms=="Delmarva Health Network, LLC"
	replace aconame_cms="Emerald Physicians" if aconame_cms=="Emerald Physician Services, LLC."
	replace aconame_cms="GGC ACO, LLC" if aconame_cms=="Greater Genesee County ACO, LLC"
	replace aconame_cms="HCP ACO CA LLC" if aconame_cms=="HCP ACO California, LLC"
	replace aconame_cms="Medical Benefits Administration Inc" if aconame_cms=="MBA - Northern California Physicians Management Group"
	replace aconame_cms="Mercy Health System ACO" if aconame_cms=="Mercy Alliance, Inc."
	replace aconame_cms="Midwest Health Coalition ACO" if aconame_cms=="Midwest Independent Physicians LLC"
	replace aconame_cms="National Rural ACO" if aconame_cms=="National Rural ACO Corporation"
	replace aconame_cms="Northern Michigan Health Network" if aconame_cms=="Northern Michigan Health Network, LLC"
	replace aconame_cms="PMC ACO" if aconame_cms=="PMC ACO LLC"
	replace aconame_cms="RRHS ACO, Inc." if aconame_cms=="Rochester Regional Health System ACO, Inc."
	replace aconame_cms="St Joseph Health Partners ACO" if aconame_cms=="St Joseph Regional Health Partners ACO"
	replace aconame_cms="Well Virginia" if aconame_cms=="Well Virginia Corporation"
	replace aconame_cms="MetroHealth Care Partners" if aconame_cms=="The MetroHealth System"
	replace aconame_cms="Saint Vincent Accountable Health Network" if aconame_cms=="Rocky Mountain Accountable Health Network, Inc"
	*^http://www.rmahn.org/
	replace aconame_cms="Saint Vincent Healthcare Partners" if aconame_cms=="Saint Vincent Shared Savings Program ACO, LLC"
	*^https://www.ahn.org/locations/saint-vincent-hospital/saint-vincent-healthcare-partners-aco
	replace aconame_cms="South Bend Clinic Accountable Care" if aconame_cms=="Michiana Accountable Care Organization, LLC"
	*^http://southbendclinic.com/accountable-care/
	replace aconame_cms="USMD Physician Services" if aconame_cms=="Medical Clinic of North Texas PLLC"
	replace aconame_cms="ACONA" if aconame_cms=="Northeast Alabama Primary Health Care, Inc."
	replace aconame_cms="ACO Providers" if aconame_cms=="AmpliPHY ACO Number 3 LLC"
	replace aconame_cms="Delaware Valley ACO" if aconame_cms=="Accountable Care Organization of Pennsylvania, LLC"
	*Reported savings for DVACO matched savings number for Pennsylvania exactly
	replace aconame_cms="Gulf Coast Health Partners" if aconame_cms=="Northwest Florida Health Partners LLC"
	*^http://www.gulfcoasthealthpartners.com/
	replace aconame_cms="MBA - Northern California Physicians Management Group" if aconame_cms=="Medical Benefits Administration Inc"
	replace aconame_cms="Oklahoma Health Initiatives" if aconame_cms=="SJFI, LLC"
	*^http://www.stjohnhealthsystem.com/media/file/1068/ACO_Website_Published_Information.pdf
	replace aconame_cms="CaroMont ACO" if aconame_cms=="CHI Continuum LLC"
	replace aconame_cms="Live Oak Care" if aconame_cms=="North Georgia HealthCare Partnership, Inc."
	replace aconame_cms="HCP ACO California, LLC" if  aconame_cms == "HCP ACO CA LLC"
	replace aconame_cms="Marshfield Clinic, Inc." if aconame_cms=="Marshfield Clinic"
	
*drop _merge

order aco_num aconame_cms start_date *_PY1 *_PY2 *_PY3 *_PY4  // BU 11/2017: added "*_PY4"
drop aco1_PY4 aco2_PY4 aco3_PY4 aco4_PY4 aco5_PY4 aco6_PY4 aco7_PY4 aco8_PY4 aco9_PY4 aco10_PY4 aco11_PY4 aco13_PY4 aco14_PY4 aco15_PY4 aco16_PY4 aco17_PY4 aco18_PY4 aco19_PY4 aco20_PY4 aco21_PY4 aco27_PY4 aco28_PY4 aco30_PY4 aco31_PY4 aco33_PY4 aco34_PY4 aco35_PY4 aco36_PY4 aco37_PY4 aco38_PY4 aco39_PY4 aco40_PY4 aco41_PY4 aco42_PY4
drop cms_hcc_riskscore_dis_by1_PY1 cms_hcc_riskscore_dis_by1_PY2 cms_hcc_riskscore_dis_by1_PY3 cms_hcc_riskscore_dis_by1_PY4 cms_hcc_riskscore_dis_by2_PY1 cms_hcc_riskscore_dis_by2_PY2 cms_hcc_riskscore_dis_by2_PY3 cms_hcc_riskscore_dis_by2_PY4 cms_hcc_riskscore_dis_by3_PY1 cms_hcc_riskscore_dis_by3_PY2 cms_hcc_riskscore_dis_by3_PY3 cms_hcc_riskscore_dis_by3_PY4 cms_hcc_riskscore_esrd_by1_PY1 cms_hcc_riskscore_esrd_by1_PY2 cms_hcc_riskscore_esrd_by1_PY3 cms_hcc_riskscore_esrd_by1_PY4 cms_hcc_riskscore_esrd_by2_PY1 cms_hcc_riskscore_esrd_by2_PY2 cms_hcc_riskscore_esrd_by2_PY3 cms_hcc_riskscore_esrd_by2_PY4 cms_hcc_riskscore_esrd_by3_PY1 cms_hcc_riskscore_esrd_by3_PY2 cms_hcc_riskscore_esrd_by3_PY3 cms_hcc_riskscore_esrd_by3_PY4 n_ab_year_dis_by1_PY1 n_ab_year_dis_by2_PY1 n_ab_year_dis_by3_PY1 n_ab_year_dis_by3_PY2 n_ab_year_dis_by3_PY3 n_ab_year_dis_by3_PY4 n_ab_year_esrd_by1_PY1 n_ab_year_esrd_by2_PY1 n_ab_year_esrd_by3_PY1 n_ab_year_esrd_by3_PY2 n_ab_year_esrd_by3_PY3 n_ab_year_esrd_by3_PY4 per_capita_exp_all_dis_by1_PY1 per_capita_exp_all_dis_by1_PY2 per_capita_exp_all_dis_by1_PY3 per_capita_exp_all_dis_by1_PY4 per_capita_exp_all_dis_by2_PY1 per_capita_exp_all_dis_by2_PY2 per_capita_exp_all_dis_by2_PY3 per_capita_exp_all_dis_by2_PY4 per_capita_exp_all_dis_by3_PY1 per_capita_exp_all_dis_by3_PY2 per_capita_exp_all_dis_by3_PY3 per_capita_exp_all_dis_by3_PY4 per_capita_exp_all_esrd_by1_PY1 per_capita_exp_all_esrd_by1_PY2 per_capita_exp_all_esrd_by1_PY3 per_capita_exp_all_esrd_by1_PY4 per_capita_exp_all_esrd_by2_PY1 per_capita_exp_all_esrd_by2_PY2 per_capita_exp_all_esrd_by2_PY3 per_capita_exp_all_esrd_by2_PY4 per_capita_exp_all_esrd_by3_PY1 per_capita_exp_all_esrd_by3_PY2 per_capita_exp_all_esrd_by3_PY3 per_capita_exp_all_esrd_by3_PY4 per_capita_exp_total_by1_PY1 per_capita_exp_total_by2_PY1 per_capita_exp_total_by3_PY1
drop current_track_1_PY4 current_track_2_PY4 current_track_3_PY4 initial_track_1_PY4 initial_track_2_PY4 initial_track_3_PY4
drop aco_state_PY1 aco_state_PY2 aco_state_PY3 aco_state_PY4 
drop gensaveloss*  // BU 12/2017: dropping because these are brought in through "MSSP quality and Savings.do" 
saveold "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/Final.ACO.SSP.PUF_innovators.dta", replace








/*
*Testing*

order *, sequential
order aco_num aconame_cms start_date
sort start_date aconame_cms


*PDFs:
*http://innovation.cms.gov/Files/x/pioneeraco-fncl-py1.pdf
*http://innovation.cms.gov/Files/x/pioneeraco-fncl-py2.pdf
*http://innovation.cms.gov/Files/x/pioneeraco-fncl-py3.pdf
*https://innovation.cms.gov/Files/x/pioneeraco-fncl-py4.pdf

*Updated: 9/20/16 to add Year 4 data
*Update by: Alex Mainor
*Updated 11/29/2017 by BU to add Year 5 data

clear
set more off

*Convert PDF to Excel, then import

	*Year 1
		import excel using "/Volumes/NSACO/NSACO Data Master/CMS/Data files/CMS raw data/pioneeraco-fncl-py1.xlsx", cellrange(A2:AR34) firstrow case(lower)
		saveold "/Volumes/NSACO/NSACO Data Master/CMS/Data files/CMS raw data/pioneeraco-fncl-p_PY1.dta", replace
	
	*Year 2
		clear
		import excel using "/Volumes/NSACO/NSACO Data Master/CMS/Data files/CMS raw data/pioneeraco-fncl-py2.xlsx", cellrange(A2:AR25) firstrow case(lower)
		saveold "/Volumes/NSACO/NSACO Data Master/CMS/Data files/CMS raw data/pioneeraco-fncl-p_PY2.dta", replace

	*Year 3
		clear
		import excel using "/Volumes/NSACO/NSACO Data Master/CMS/Data files/CMS raw data/pioneeraco-fncl-py3.xlsx", cellrange(A2:AR22) firstrow case(lower)
		saveold "/Volumes/NSACO/NSACO Data Master/CMS/Data files/CMS raw data/pioneeraco-fncl-p_PY3.dta", replace
		
	*Year 4
		clear
		import excel "/Volumes/NSACO/NSACO Data Master/CMS/Data files/CMS raw data/pioneeraco-fncl-py4.xlsx", cellrange(A2:AQ14) firstrow case(lower)
		saveold "/Volumes/NSACO/NSACO Data Master/CMS/Data files/CMS raw data/pioneeraco-fncl-p_PY4.dta", replace
	*/
	/*
	*Year 5
		clear
		import excel "/Volumes/NSACO/NSACO Data Master/CMS/Data files/CMS raw data/pioneeraco-fncl-py5.xlsx", cellrange(A2:AQ14) firstrow case(lower)
		saveold "/Volumes/NSACO/NSACO Data Master/CMS/Data files/CMS raw data/pioneeraco-fncl-p_PY5.dta", replace
*/
				
	

foreach year in _PY1 _PY2 _PY3 _PY4 _PY5 {

	use "/Volumes/NSACO/NSACO Data Master/CMS/Data files/CMS raw data/pioneeraco-fncl-p`year'.dta", clear

	*Destring
	
		destring totalbenchmarkminusalignedbe, replace ignore("%")
	
	*Change string to dichotomous (1="Yes")
	
		encode successfullyreportedquality7, generate(successfullyreportedqualitycat)
		drop successfullyreportedquality7
		rename successfullyreportedqualitycat successfullyreportedquality
		rename totalbenchmarkexpendituresmin totalbenchmarkexpendminus

	*Specify performance year in varnames

		foreach var of varlist * {
			rename `var' `var'`year'
		}

	*Change aconame back to regular
	
		rename aconame`year' aconame_cms
	
	*Matching ACO Names to CMS format 

		replace aconame_cms="Allina Hospitals and Clinics" if aconame_cms=="Allina Health"
		replace aconame_cms="Beth Israel Deaconess Physician Organization" if aconame_cms=="Beth Israel Deaconess Care Organization" | aconame_cms == "Beth Israel Deaconness Care Organization"		
		replace aconame_cms="Dartmouth Hitchcock ACO" if aconame_cms=="Dartmouth-Hitchcock ACO"
		replace aconame_cms="Healthcare Partners Nevada" if aconame_cms=="Healthcare Partners of Nevada"
		*http://www.hcpnv.com/read_news/view.asp?ID=9&CID=6

		replace aconame_cms="Beacon Health, LLC" if aconame_cms=="Beacon Health"
		replace aconame_cms="Brown & Toland Medical Group" if aconame_cms=="Brown & Toland Physicians"
		replace aconame_cms="Monarch HealthCare ACO" if aconame_cms=="Monarch HealthCare"
		replace aconame_cms="OSF Healthcare" if aconame_cms=="OSF Healthcare System"
		replace aconame_cms="Partners Healthcare" if aconame_cms=="Partners HealthCare"
		replace aconame_cms="Steward Healthcare Network, Inc" if aconame_cms=="Steward Healthcare Network"

		replace aconame_cms="JSA Medical Group (division of HealthCare Partners)" if aconame_cms=="JSA Medical Group, a division of HealthCare Partners"
		replace aconame_cms="North Texas ACO/Plus!" if aconame_cms=="Plus! / North Texas ACO"
		replace aconame_cms="Primecare Medical Network" if aconame_cms=="PrimeCare Medical Network"
		replace aconame_cms="Mount Auburn Cambridge Independent Practice Association (MACIPA)" if aconame_cms=="Mount Auborn Cambridge Independent Practice Association (MACIPA)"
		replace aconame_cms="Franciscan Alliance ACO" if aconame_cms=="Franciscan Alliance"
		replace aconame_cms="HealthCare Partners Nevada" if aconame_cms=="Healthcare Partners Nevada"
		replace aconame_cms="HCP ACO California, LLC" if aconame_cms=="Healthcare Partners of California"
		replace aconame_cms="Physician Health Partners, LLC" if aconame_cms=="Physician Health Partners"
		replace aconame_cms="Premier Choice ACO, Inc." if aconame_cms== "Primecare Medical Network"	 //  this is the original match from NSACO; primecare select may be related but has different service area.
	 
		*replace aconame_cms = "POM" if aconame_cms=="University of Michigan"  //
		replace aconame_cms = "Michigan Pioneer ACO" if aconame_cms=="Michigan Pioneer Aco"  // BU: added 05/30/18
		
		
		replace aconame_cms="HCP ACO California, LLC" if  aconame_cms == "HCP ACO CA LLC"
		*http://innovation.cms.gov/files/x/pioneer-aco-model-selectee-descriptions-document.pdf
		*Change name to MSSP version (switched after y1)
		
		replace aconame ="Genesys PHO, L.L.C." if aconame_cms=="Genesys PHO"

	*Misc edits for individual years
	
		capture replace aco26_PY1="." if aco26_PY1=="N/A"
		capture destring aco26_PY1, replace
		capture destring qualityscore89_PY2, replace ignore("%")
		capture destring qualityscore89_PY3, replace ignore("%")
		capture destring aco40_PY4, replace ignore("N/A")
		
		*Year 1 quality score all "P4R" because quality score based on complete/accurate reporting
		*Need to destring because quality scores in years 2 and 3 are numerical
		*Can't label because other values have decimals (Stata labels are buggy)
		capture replace qualityscore89_PY1=".r" if qualityscore89_PY1=="P4R"
		capture destring qualityscore89_PY1, replace
		
		rename successfullyreportedquality`year' reportedquality`year'
		
	rename qualityscore89`year' qualityscore`year'
	rename totalalignedbeneficiaries1`year' totalalignedbeneficiaries`year'
	rename totalbenchmarkexpenditures23`year' totalbenchmarkexpenditures`year'
	
	*Rename to match MSSP varnames
	
	rename earnedsharedsavingspaymentso`year' earnedsavingsowelosses`year'
	rename totalbenchmarkminusalignedbe`year' totalbenchmarkminassignedben`year'
	rename totalactualexpendituresforal`year' totalexpenditures`year'
	rename totalalignedbeneficiaries`year' totalassignedbeneficiaries`year'
	capture gen pioneer=1 //BU: added 5/30/18 to mark original pioneers	
	saveold "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/PioneerACO`year'.dta", replace
	
	}

 

 use "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/PioneerACO_PY1.dta", clear
foreach year in   _PY2 _PY3 _PY4 _PY5 {
	merge 1:1 aconame_cms using "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/PioneerACO`year'.dta"
	rename _merge _merge_`year'
	}
capture gen pioneer=1
drop if missing(totalassignedbeneficiaries_PY1)
save  "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/Pioneer_all.dta", replace
	
 

 import excel "/Volumes/NSACO/NSACO Data Master/CMS/Data files/CMS raw data/nextgenpy1.xlsx", sheet("Sheet1") firstrow clear
 
 drop B
 rename C start_date  //these are start dates to account for previous MSSP and/or Pioneer contracts
 
 
rename TotalAlignedBeneficiaries1 totalassignedbeneficiaries 
rename TotalBenchmarkExpenditures23 totalbenchmarkexpenditures

rename TotalActualExpendituresforAl totalexpenditures 
rename TotalBenchmarkExpendituresMin totalbenchmarkexpendminus
rename TotalBenchmarkMinusAlignedBe totalbenchmarkminassignedben 
rename EarnedSharedSavingsPaymentsO earnedsavingsowelosses 
rename SuccessfullyReportedQuality7 reportedquality 
rename QualityScore89 qualityscore 

foreach x in 1 2 3 4 5 6 7 8 9 10 13 14 15 16 17 18 19 20 21 27 28 30 31 33 34 35 36 37 38 39 40 41 42 {
	rename ACO`x' aco`x'
	}
rename DMComposite dmcomposite

 

foreach var in totalassignedbeneficiaries totalbenchmarkexpenditures totalexpenditures totalbenchmarkexpendminus ///
totalbenchmarkminassignedben earnedsavingsowelosses reportedquality qualityscore aco1 aco2 aco3 aco4 aco5 aco6 aco7 ///
aco8 aco9 aco10 aco13 aco14 aco15 aco16 aco17 aco18 aco19 aco20 aco21 dmcomposite aco27 aco28 aco30 aco31 aco33 aco34 ///
aco35 aco36 aco37 aco38 aco39 aco40 aco41 aco42 {
gen `var'_PY1 = `var' if start_date == 20454 
gen `var'_PY5 = `var' if start_date == 18993 & !inlist(ACOName, "Bellin", "Beacon Health", "Steward", "Trinity Health")
gen `var'_PY4 = `var' if start_date == 19175 | start_date==19359 |  inlist(ACOName, "Bellin", "Beacon Health", "Steward", "Trinity Health")
gen `var'_PY2 = `var' if start_date ==20089
drop `var'
}


	 
	rename ACOName aconame_cms
	gen aconame_cms_nextgen = aconame_cms
	
	capture gen nextgen=1
	
	replace aconame_cms = "Bellin-ThedaCare Healthcare Partners" if aconame_cms=="Bellin"	
	replace aconame_cms = "Park Nicollet Health Services" if aconame_cms=="Park Nicollet"
	replace aconame_cms ="OSF Healthcare" if aconame_cms=="OSF"
	*replace aconame_cms ="Allina Hospitals and Clinics" if aconame_cms==	//don't see on Nextgen 2016
	replace aconame_cms ="Beacon Health, LLC" if aconame_cms=="Beacon Health"   
	
	replace aconame_cms ="Cornerstone Health Enablement Strategic Solutions, LLC"  if aconame_cms=="CHESS NextGen"
	replace aconame_cms ="Steward Healthcare Network, Inc" if aconame_cms==	"Steward"
	replace aconame_cms = "Deaconess Care Integration, LLC"  if aconame_cms=="Deaconess"
	replace aconame_cms ="UnityPoint Health Partners" if aconame_cms=="Iowa Health"
	replace aconame_cms = "Pioneer Valley Accountable Care, LLC" if aconame_cms=="Pioneer Valley Accountable Care"		
	replace aconame_cms ="Trinity Pioneer ACO" if aconame_cms=="Trinity Health" 
	gen nextgen2016=1 //BU added 5/30/18 to mark nextgens with 2016 performance data.
	save "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/NextGenACO_PY4.dta", replace
	
	*/
	

use "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/MSSP Quality and Savings_innovators_version.dta", clear
replace aconame_cms="Mercy ACO, LLC (Iowa)" if aconame_cms =="Mercy ACO, LLC" & bene_states_PY1=="Iowa"
 capture drop _merge*	
save "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/MSSP Quality and Savings_innovators_version.dta", replace

use "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/Final.ACO.SSP.PUF_innovators.dta", clear
 
replace aconame_cms="Mercy ACO, LLC (Iowa)" if aconame_cms =="Mercy ACO, LLC" & aco_num == "A42388"
capture gen mssp = 1 //BU added 05/30/18 to mark MSSPs
save "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/Final.ACO.SSP.PUF_innovators.dta", replace


*use "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/Final.ACO.SSP.PUF.dta", clear






	

use "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/Pioneer_all.dta", clear
drop _merge*
 
merge m:1 aconame_cms using  "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/MSSP Quality and Savings_innovators_version.dta", update
rename _merge merge1


merge 1:m aconame_cms using "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/Final.ACO.SSP.PUF_innovators.dta", update
drop _merge
tostring reportedquality_PY*, replace force
 
merge m:1 aconame_cms using "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/NextGenACO_PY4.dta", update 
*drop in 1/3  //dropping non-observation rows brought in with excel; remove from source files and then comment this out
*drop in 416 //dropping non-observation rows brought in with excel; remove from source files and then comment this out

 
gsort aconame_cms
*drop in 1/6
drop _merge*
tostring reportedquality_PY*, replace force

merge m:1 aconame_cms using "/Volumes/NSACO/NSACO Data Master/CMS/Data files/BU_working/NextGenACO_PY4.dta"	

gen aco29_PY4 = .  
gen aco29_PY5= .

forval x=1/5 {
				gen aco8_PY`x'_neg = -aco8_PY`x'
				xtile aco8_PY`x'_pct = aco8_PY`x'_neg, nquantiles(100)
				drop aco8_PY`x'_neg
				label variable aco8_PY`x'_pct "Percentile - Risk Standardized, All Condition Readmission in performance year `x'"
			}
			
	forval x=1/5 {
				gen aco9_PY`x'_neg = -aco9_PY`x'
				xtile aco9_PY`x'_pct = aco9_PY`x'_neg, nquantiles(100)
				drop aco9_PY`x'_neg
				label variable aco9_PY`x'_pct "Percentile - COPD or Asthma in Older Adults in performance year `x'"
			}
			
	forval x=1/5 {
				gen aco10_PY`x'_neg = -aco10_PY`x'
				xtile aco10_PY`x'_pct = aco10_PY`x'_neg, nquantiles(100)
				drop aco10_PY`x'_neg
				label variable aco10_PY`x'_pct "Percentile - Heart Failure in performance year `x'"
			}
	
		forval x=1/5 {
				gen aco27_PY`x'_neg = -aco27_PY`x'
				xtile aco27_PY`x'_pct = aco27_PY`x'_neg, nquantiles(100)
				drop aco27_PY`x'_neg
				label variable aco27_PY`x'_pct "Percentile - Poor Diabetes Control in performance year `x'"
			}
		
		
		* Add aco33 (One of the components of the CAD composite?)
		forval x=1/5 {
				egen aco_PY`x'comp_new=rmean(aco1_PY`x' aco2_PY`x' aco3_PY`x' aco4_PY`x' aco5_PY`x' aco6_PY`x' aco7_PY`x' aco8_PY`x'_pct /* aco9_PY`x'_pct ///
				aco10_PY`x'_pct  aco11_PY`x' */  aco13_PY`x' aco14_PY`x' aco15_PY`x' aco16_PY`x' aco17_PY`x' aco18_PY`x' aco19_PY`x' aco20_PY`x' aco21_PY`x'  aco27_PY`x'_pct aco28_PY`x' /* aco29_PY`x' */  aco30_PY`x' aco31_PY`x' aco33_PY`x')  //ACO 29 and 11 commented out because not available 2016 and nextgen, respectively.
				label var aco_PY`x'comp_new "Overall quality score for performance year `x' new version"
			}
	
	*replace qualscore_PY2 = perfyear_qual_scre_PY2 if missing(qualscore_PY2)
	*replace qualscore_PY3 = perfyear_qual_scre_PY3 if missing(qualscore_PY3)
	replace n_ab_PY1 =totalassignedbeneficiaries_PY1 if missing(n_ab_PY1)
	replace n_ab_PY2 = totalassignedbeneficiaries_PY2 if missing(n_ab_PY2)
	replace n_ab_PY3 = totalassignedbeneficiaries_PY3 if missing(n_ab_PY3)
	replace n_ab_PY4 = totalassignedbeneficiaries_PY4 if missing(n_ab_PY4)
	replace n_ab_PY5 = totalassignedbeneficiaries_PY5 if missing(n_ab_PY5) 
	
	rename start_date aco_start
	capture gen finalsharerate_PY5=.
	 
	keep aconame_cms aco_start n_ab_PY* aco_PY1comp_new aco_PY2comp_new aco_PY3comp_new aco_PY4comp_new aco_PY5comp_new	finalsharerate_PY1 finalsharerate_PY2 finalsharerate_PY3 finalsharerate_PY4	finalsharerate_PY5 earnedsavingsowelosses* earnsaveloss*	pioneer mssp nextgen	
	foreach year in _PY1 _PY2 _PY3 _PY4 _PY5 {
	gen sharedsavings`year'= earnedsavingsowelosses`year'
	
	}
 	foreach year in _PY1 _PY2 _PY3 _PY4 {
	replace sharedsavings`year'  = earnsaveloss`year' if missing(sharedsavings`year')
	}
	
	drop earn*
	order aco_start pioneer mssp nextgen
	gsort aconame_cms
	order  aconame_cms	
	replace aco_start= date("01/01/2012", "MDY") if pioneer==1
	
	
foreach year in _PY1 _PY2 _PY3 _PY4 _PY5 {
label var sharedsavings`year'  "Shared Savings in NSACO `year'"
}
	
foreach year in _PY1 _PY2 _PY3 _PY4 _PY5 {
label var  aco`year'comp_new "TDI derived quality score for NSACO `year'"
}

foreach year in _PY1 _PY2 _PY3 _PY4 _PY5 {
label var  n_ab`year'  "assigned beneficiaries for NSACO `year'"
}

foreach year in _PY1 _PY2 _PY3 _PY4 _PY5 {
label var  finalsharerate`year'  "Final share rate for NSACO `year'"
}

label var pioneer "Pioneer in at least one year 2012-2016"
label var mssp "MSSP in at least one year 2012-2016"
label var nextgen "reported Nextgen performance 2016"

	order aconame_cms aco_start pioneer mssp nextgen n_ab* shared* aco_PY* final*
	
	
	save "/Volumes/NSACO/NSACO Data Master/CMS/merge2016PUFtoNSACO_working/ACO Innovators/aco_innovators_puf_data_051418.dta", replace
