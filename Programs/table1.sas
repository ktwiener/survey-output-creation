*********************************************************************
*  Assignment:    Final Project                                   
*                                                                    
*  Description:   Final Project Creating Standard Tables
*
*  Name:          Catie Wiener
*
*  Date:          05/04/2018                                       
*------------------------------------------------------------------- 
*  Job name:      table1.sas
*
*  Purpose:       Creates Table 1 From Survey Data
*
*  Language:      SAS, VERSION 9.4  
*
*  Input:         DS.ADQS
*
*  Output:        TABLE1.RTF
*                                                                    
********************************************************************;

/*Create Column for All Subjects*/
data table;
	length &exposure $40;
	set ds.adqs (rename=(&exposure=exp_temp));

	expord = input(put(exp_temp,$&exposure.bin.),best.)+1;
	&exposure = put(expord-1,&exposure.disp.);

	output;
	&exposure = "All Subjects";
	expord = 3;
	output;
run;

proc sql;
	select distinct expord, &exposure from table;
	quit;
/*Create denominators and percentages*/
proc sql noprint;
	create table denoms as
	select &exposure
		  ,expord
		  ,count (distinct usubjid) as denoms
	from table
	group by expord, &exposure
	order by expord
	;

	select min(expord) into: minexp from denoms;
	select max(expord) into: maxexp from denoms;

	create table combine as
	select a.&exposure
		   ,b.expord
		   ,paramn
		   ,put(paramn,headers.) as label1
		   ,avalc
		   ,put(count(distinct usubjid), 5.)||" ("||put(100*count(distinct usubjid)/denoms, 5.1)||")" as counts
	from table as a left join denoms as b
	on a.&exposure = b.&exposure
	where paramcd ^= upcase("&exposure")
	group by b.expord, a.&exposure, paramn, label1, avalc, denoms
	order by paramn, label1, avalc;
quit;

proc print data = combine;
	var paramn label1 avalc expord &exposure ;
run;

/*Transpose to Get table ready for Support*/
proc transpose data = combine out = comb_t prefix=col;
	by paramn label1 avalc;
	var counts;
	id expord;
	idlabel &exposure;
run;


/*Fill in missing counts*/
data comb_t1;
	set comb_t;

	array cols (*) col:;
		do i = 1 to dim (cols);
			if missing (cols(i)) then cols(i) = '0';
		end;

	freqsort = input( scan(col3,1), best.);
	if index(col1,'Other') then freqsort = 999;
run;

proc sort data = comb_t1;
	by paramn descending freqsort;
run;

/*Creating sorts and overall value*/
data comb_t2;
	set comb_t1;
	by paramn;
	where not missing (avalc);
	sort2 = 2;
	if paramn ne 1 then avalc = '^R"\li400" '||avalc;
	else avalc = "Overall";
	output;
	if first.paramn and paramn ne 1 then do;
		avalc = label1;
		sort2 = 1;
		call missing (of col1 - col3);
		output;
	end;
run;

proc sort data = comb_t2 out = table1;
	by paramn sort2 descending freqsort  ;
run;


/*Assigning Final Sort*/
data table1;
	set table1;
	by paramn sort2 descending freqsort;
	where not missing (avalc);
	if first.paramn then finsort = 0;
	finsort+1;
run;

ods tagsets.rtf file = "&direc.\Reports\table1.rtf" options(continue_tag="no") style=newrtf;
title justify = left "&title1";
ods listing close;
proc report data = table1 nowd headline missing
	style=[frame=hsides] split = "!"; 

	column paramn finsort avalc 

	%macro cols;
		%do m = &minexp %to &maxexp;
			col&m 
		%end;;

		define paramn / order order=internal noprint;
		define finsort / order order=internal noprint;

		define avalc			   / display " " style(column)=[just=left cellwidth=2.5in vjust=bottom font_size=8.5pt]
		  								 style(header)=[just=left font_size=8.5pt];;

		%do k = &minexp %to &maxexp;
			define col&k 	   / display &st;
		%end;
		%if %length(&footnote1) ^= 0 %then %do;
			footnote justify = center "&footnote1";
		%end;
		%else %do;
			footnote;
		%end;
		%mend;
	%cols;
run;

ods tagsets.rtf close;

footnote;

ods listing;
