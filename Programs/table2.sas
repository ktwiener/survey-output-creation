*********************************************************************
*  Assignment:    Final Project                                   
*                                                                    
*  Description:   Final Project Creating Standard Tables
*
*  Name:          Catie Wiener
*
*  Date:          05/04/2018                                       
*------------------------------------------------------------------- 
*  Job name:      table2.sas
*
*  Purpose:       Creates crude table 2
*
*  Language:      SAS, VERSION 9.4  
*
*  Input:         DS.ADQS
*
*  Output:        table2.rtf
*                                                                    
********************************************************************;

/*Assign correct dichotomization*/
data adqs;
	set ds.adqs;
	dummy = 1;

	expn = input(put(&exposure,$&exposure.bin.),best.);
	outn = input(put(&outcome,$&outcome.bin.),best.);

run;

proc sort data = adqs;
	by descending expn descending outn;
run;

/*Overall OR*/
ods output OddsRatioExactCL = OR;
proc freq data = adqs order = data;
	tables expn*outn/ out = overall relrisk;
	exact or;
	where paramcd = upcase("&Exposure");
run;

/*Counts per exposure*/
proc freq data = adqs order=data;
	tables expn / out = exp_all ;
	where paramcd = upcase("&exposure");
run;

proc transpose data = OR out = OR_T;
	by table;
	var cvalue1;
	id name1;
	where name1 in ('_RROR_','L_RROR','XL_RROR','U_RROR','XU_RROR');
run;

/*Format OR and CI*/
data orfmt (keep = expn sig value);
	length sig $40;		
	set or_t;
	expn = 1;

	sig = put(input(_RROR_,best.),5.2)||" ("||put(input(L_RROR,best.),5.2)||", "||put(input(U_RROR,best.),5.2)||")";

	value = _rror_;
run;

/*Format frequencies*/
data exp;
	merge overall exp_all (rename=(count=denom));
	by descending expn;
	values = put(count,5.)||" ("||put(100*count/denom,5.1)||")";

	outdisp = put(outn,&outcome.disp.); *how outcome will be displayed;
run;

proc transpose data =exp out = exp_t;
	by descending expn denom;
	var values;
	id outn;
	idlabel outdisp;
run;

proc sort data = exp_t;
	by expn;
run;

/*Put together final table*/
data final;			
	merge exp_t (in=a)
	orfmt (in=b)
    ;
	by expn;

	exp = strip(put(expn,&exposure.disp.))||" (N="||strip(put(denom,best.))||")";

run;

proc sort data = final;
	by descending expn;
run;

/*Assign Final Sort*/
data final;	
	set final;
	by descending expn;
	sort + 1;
run;

ods tagsets.rtf file = "&direc\Reports\table2.rtf" options(continue_tag="no") style=newrtf;

title justify = center "&title2";
ods listing close;
proc report data = final nowd headline missing
	style=[frame=hsides] split = "!" ; 
	column sort exp ("&_line Prevalence" _1 _0) sig ;

	define sort / order order = internal noprint;

	define exp    / display "Exposure" style(column)=[just=left cellwidth=1.2in vjust=bottom font_size=8.5pt]
		  								 	  			    style(header)=[just=left font_size=8.5pt];
	define _1 	   / display  style(column)=[just=center cellwidth=0.7in vjust=bottom font_size=8.5pt]
		  									 style(header)=[just=center font_size=8.5pt];
	define _0	   / display  style(column)=[just=center cellwidth=0.7in vjust=bottom font_size=8.5pt]
		  											style(header)=[just=center font_size=8.5pt];
	define sig	   / display "Odds Ratio (95% CI)" style(column)=[just=left cellwidth=1.2in vjust=bottom font_size=8.5pt]
		  								 	  			    style(header)=[just=left font_size=8.5pt];

	%macro foot;
	%if %length(&footnote2) ^= 0 %then %do;
		footnote justify = center "&footnote2";
	%end;
	%else %do;
		footnote;
	%end;
	%mend;
	%foot;
run;

ods listing;
ods tagsets.rtf close;

footnote;
