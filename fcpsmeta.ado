/*******************************************************************************
*                                                                              *
* Stata program to attach standardized metadata to commonly used data elements *
*                                                                              *
*******************************************************************************/

// Drops program from memory if already loaded
cap prog drop fcpsmeta

// Defines the program named fcpsmeta
prog def fcpsmeta

	// Defines the calling syntax
	syntax [, AGGregate ] 
	
	// Defines the minimum version of Stata required for the program
	version 14.0
	
	// Change end of line delimiter
	#d ;

	/* Creates value labels that can be used for aggregated data and individual
	student level data.  */
	la def ell 			.a "All Students" 
						0 "Not an English Learner" 
						1 "English Learner", modify;

	la def frl 			.a "All Students" 
						0 "Full-Price Meals" 
						1 "Reduced-Price Meals" 
						2 "Free Meals", modify;

	la def gap 			.a "All Students" 
						0 "Not in Gap Group" 
						1 "Gap Group (non-duplicated)", modify;

	la def tag 			.a "All Students"  
						0 "General Education" 
						1 "Primary Talent Pool" 
						2 "Gifted/Talented", modify;

	la def swd 			.a "All Students"  
						0 "No Identified Disabilities"  
						1 "Disability-With IEP (Total)", modify;

	la def sex 			.a "All Students" 0 "Male" 1 "Female", modify;

	la def section504 	.a "All Students"  
						0 "Does Not Have a 504 Plan"  
						1 "Has a 504 Plan", modify;

	la def refugee 		.a "All Students"  
						0 "Not a Refugee"  
						1 "Refugee", modify;

	la def race 		.a "All Students"  
						1 "Hispanic"  
						2 "American Indian or Alaska Native"  
						3 "Asian" 4 "African American"  
						5 "Native Hawaiian or Other Pacific Island"  
						6 "White (Non-Hispanic)"  
						7 "Two or more races", modify;

	la def migrant 		.a "All Students"  
						0 "Non-Migrant Family Student"  
						1 "Migrant Family Student - Inactive"  
						2 "Migrant Family Student - Active", modify;

	la def immigrant 	.a "All Students"  
						0 "Not an Immigrant"  
						1 "Immigrant", modify;

	la def hhm 			.a "All Students"  
						0 "Stable Housing"  
						1 "Homeless/Highly Mobile", modify;

	la def grade 		.a "All Students" 	0 "Kindergarten" 	1 "1st Grade"  
						2 "2nd Grade" 		3 "3rd Grade" 		4 "4th Grade"  
						5 "5th Grade" 		6 "6th Grade" 		7 "7th Grade"  
						8 "8th Grade" 		9 "9th Grade" 		10 "10th Grade"  
						11 "11th Grade" 	12 "12th Grade" 	14 "Grade 14"  
						97 "Pre-K" 			98 "Pre-K" 			99 "Pre-K", modify;
						
	la def kprmthlev	1 "Novice" 2 "Apprentice" 
						3 "Proficient" 4 "Distinguished", modify;					

	// Copies value labels for other subject area
	la copy kprmthlev kprrlalev;
	
	la def pbis			0 "Not at School Implementing PBIS" 
						1 "Is at School Implementing PBIS", modify;
						
	la def enrtype		0 "Secondary" 1 "Primary", modify;					
	
	// Back to original end of line delimiter
	#d cr
	
	// Local macros store variable labels
	loc schnm "School Name"
	loc grade "Grade Level"
	loc sex "Student Sex"
	loc race "Ethnoracial Identity"
	loc swd "Students with Disabilities"
	loc ell "English Learners"
	loc frl "Economic Disadvantaged Status"
	loc tag "Gifted/Talented"
	loc hhm "Homeless/Highly Mobile"
	loc calid "Calendar ID"
	loc schid "School ID"
	loc enrtype "Enrollment Type"
	loc enrid "Enrollment ID"
	loc pid "Person ID"
	loc schyr "School Year"
	loc sasid "State Assigned Student ID"
	loc stdid "Student Number"
	loc firstnm "Student First Name"
	loc mi "Student Middle Initial"
	loc lastnm "Student Last Name"
	loc dob "Student Date of Birth"
	loc sdate "Enrollment Start Date"
	loc edate "Enrollment End Date"
	loc usentry "Date First Entered US"
	loc gap "GAP Group Inidicator"
	loc migrant "Migrant Family Indicator"
	loc section504 "Section 504 Plan Indicator"
	loc immigrant "Immigrant Student Status Indicator"
	loc refugee "Refugee Student Status Indicator"
	loc pbis "Positive Behavior Intervention Strategies Indicator"
	loc startalk "STARTALK Rostered Student"
	loc ststatus "STARTALK Status"
	loc progattnd "STARTALK Attendance"

	// Would print a list of all value labels without the qui prefix
	qui: la dir

	// Stores the names of all the value labels
	loc x `r(names)'

	// Would print a list of all variable names without the qui prefix
	qui: ds

	// Stores the name of all the variables in local macro thevars
	loc thevars `r(varlist)'
	
	// Loop over the values in the local macro thevars
	foreach v of loc thevars {
	
		// Will only do this on enrtype if it is a 1 character string
		if "`v'" == "enrtype" & "`: type enrtype'" == "str1" {
			
			// Replaces the P flag with a 1 and 0 for all other enrollment types
			qui: replace `v' = cond(`v' == "P", "1", "0")
			
			// Casts the variable as a numeric value
			qui: destring `v', replace
			
		} // End of IF Block
		
		// Checks if the variable contains only numeric integer values
		if inlist("`: type `v''", "byte", "int", "long") {		
		
			// If the variable is a member of the set of value label names
			if `: list v in x' {
			
				// Apply the value label to its variable
				la val `v' `v'
				
				// If the aggregate option is specified replaces system missing
				// with extended missing values so they can be labeled
				if !mi("`aggregate'") qui: replace `v' = .a if mi(`v')
				
			} // End IF Block for variables with defined value labels
			
		} // End IF Block for integer valued variables
		
		// Applies variable labels to variables based on their name and captures
		// any error messages that would be thrown if one isn't found
		cap la var `v' "``v''"

	} // End Loop over the variable list
	
	// Passes the list of variables to the test labels subroutine
	testlabels `thevars'
	
// End of program to label data
end	
		
// Defines subroutine for labeling testscore variables		
prog def testlabels

	// Defines the syntax used to call the subroutine
	syntax varlist
		
	// Define a series of local macros to construct variable labels
	loc map "NWEA MAP "
	loc kpr "KPREP "
	loc acc "ACCESS "
	loc rdg "Reading "
	loc tot "Composite "
	loc lst "Listening "
	loc spk "Speaking "
	loc wrt "Writing "
	loc ora "Oral Language "
	loc cmp "Comprehension "
	loc lrc "Literacy "
	loc rla "Reading/Language Arts Assessment "
	loc mth "Math Assessment "
	loc sc "Scaled Score"
	loc pct "Percentile"
	loc lev "Performance Level"
	loc 1 "Fall" 
	loc 2 "Winter" 
	loc 3 "Spring"
	loc lan "Language "

	// Loop over the test score variable names
	foreach v in `varlist' {
	
		// Use the first three characters of the variable name to identify the test
		loc testnm `"``: di substr(`"`v'"', 1, 3)''"'
		
		// Test whether or not this variable has a test type prefix
		if inlist("`: di substr(`"`v'"', 1, 3)'", "map", "kpr", "acc") {
		
			// Next three to identify the subject area
			loc subject `"``: di substr(`"`v'"', 4, 3)''"'
			
			// Gets the length of the variable name
			loc chk `= length(`"`v'"')'

			// If the variable ends with a number
			if inlist(substr(`"`v'"', -1, 1), "1", "2", "3") {
			
				// If the length of the variable name is 10, there are three characters to retrieve
				if `chk' == 10 loc scale `"``: di substr(`"`v'"', 7, 3)''"'
				
				// Else two characters (scaled score)
				else loc scale `"``: di substr(`"`v'"', 7, 2)''"'
				
				// The number at the end identifies the period in the year for the test window
				loc period `"``: di substr(`"`v'"', -1, 1)''"'	
				
			} // End IF Block for MAP assessment data
			
			// For other assessment data
			else {
				
				// Gets the scale type
				loc scale `"``: di substr(`"`v'"', 7, 3)''"'	
				
				// Sets this local macro to a null value
				loc period 
				
			} // End ELSE Block
			
			// Combine the local macros from the loop to construct the label
			loc labeled `"`testnm' `period' `subject' `scale'"'
			
			// Remove extra white space from the label when assigning it to variable
			la var `v' `"`: di ustrregexra(`"`labeled'"', "\s+", " ")'"'
			
		} // End of IF block for test score variables	
		
	} // End Loop over test data variables		
	
// End of subroutine	
end		

