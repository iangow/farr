insheet using "public-float-data-complete.csv", clear
gen publicfloatr=real(publicfloat)/1000000
drop if missing(publicfloatr)
rename fiscalyear fyear
rename gvkey gvkeyr
sort gvkeyr fyear publicfloatr
by gvkeyr: drop if fyear==fyear[_n-1]
drop cik

gen publicfloat2002=publicfloatr if publicfloatyear==2002
gen publicfloat2004=publicfloatr if publicfloatyear==2004
sort gvkeyr
by gvkeyr: egen float2002=mean(publicfloat2002)
sort gvkeyr

by gvkeyr: egen float2004=mean(publicfloat2004)

keep if float2002!=. | float2004!=.

keep gvkeyr float2002 float2004 publicfloatr

sort gvkeyr
 by gvkeyr: drop if gvkeyr==gvkeyr[_n-1]
 
gen accfiler=float2002>=75
