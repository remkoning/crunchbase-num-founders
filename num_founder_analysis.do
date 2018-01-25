// Data from https://data.crunchbase.com/docs/daily-csv-export

import delimited "/Users/rkoning/Dropbox/Research/crunchbase/2017-01/csv_export/jobs.csv", varnames(1) encoding(ISO-8859-1)clear

// Make a role as a founder if "founder" is in the title
gen lower_title = lower(title)
gen founder = strpos(lower_title, "founder") > 0

// Make sure if they are a founder they are always
// marked as a founder across all roles in a company
bysort person_uuid org_uuid: egen founder2 = max(founder)

// If multiple roles keep only one per company
duplicates drop person_uuid org_uuid, force

// Number of founders for each company
collapse (sum) founder, by(org_uuid)

drop if mi(org_uuid)

//  Right censor the data at 5 founders since there are some
// data errors (69 founders must be wrong, right!?!?!)

replace founder = 5 if founder > 5

// save out file to merge on to some other stuff
sort org_uuid
save "~/Downloads/number_founders.dta", replace

// Load in the startup data
import delimited "/Users/rkoning/Dropbox/Research/crunchbase/2017-01/csv_export/organizations.csv", varnames(1) encoding(ISO-8859-1)clear

// Okay merge on the number of founders data
rename uuid org_uuid
sort org_uuid
drop if mi(org_uuid)
merge 1:1 org_uuid using "~/Downloads/number_founders.dta"

// Some don't match, not data on number of founders?
keep if _m == 3
drop _m

// Some have 0 founders, so lets remove those...
keep if founder > 0

// 493,997 organizations, 117,554 with number of founders


gen solo_founder = (founder == 1)

gen ipo = (status == "ipo")
gen acquired = (status == "acquired")
gen raised_funding = (funding_rounds > 0)
gen closed = (status == "closed")

label var solo_founder "Sole Founder?"

label var ipo "IPO?"
label var acquired "Acquired?"
label var raised_funding "Raised Funding?"

// Check other DVs based on Ethan's twitter comment 
// https://twitter.com/emollick/status/956574711877722112
label var closed "Shut Down?"

eststo clear
eststo: reg raised_funding solo_founder, robust
eststo: reg acquired solo_founder, robust
eststo: reg ipo solo_founder, robust
eststo: reg closed solo_founder, robust

tab solo_founder
esttab, label noabbrev







