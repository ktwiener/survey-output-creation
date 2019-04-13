*********************************************************************
*  Assignment:    Final Project                                   
*                                                                    
*  Description:   Final Project Creating Standard Tables
*
*  Name:          Catie Wiener
*
*  Date:          05/04/2018                                       
*------------------------------------------------------------------- 
*  Job name:      table3.sas
*
*  Purpose:       Creates stratified table 3
*
*  Language:      SAS, VERSION 9.4  
*
*  Input:         DS.ADQS
*
*  Output:        table3.rtf
*                                                                    
********************************************************************;

data adqs;
	set ds.adqs;
	dummy = 1;

	expn = input(put(&exposure,$&exposure.bin.),best.);
	outn = input(put(&outcome,$&outcome.bin.),best.);

run;

/*Stratified Output*/
%macro strat;
%do c = 1 %to &maxcov;
	data adqs;
		set adqs;
		&&cov&c..n = input(put(&&cov&c,$&&cov&c..bin.),best.); *Apply correct dichotomization;
	run;

	proc sort data = adqs;
		by descending expn descending outn descending &&cov&c..n;
	run; 

	/*Get OR estimates*/
	ods output OddsRatioExactCL = _Strat&c;
	proc freq data = adqs order=data;
		tables &&cov&c..n*expn*outn / out = var&c relrisk ;
		exact or;
		where paramcd = upcase("&&cov&c");
	run;

	proc transpose data = _Strat&c out = Strat&c;
		by table;
		var cvalue1;
		id name1;
		where name1 in ('_RROR_','L_RROR','XL_RROR','U_RROR','XU_RROR');
	run;

	/*Get min counts to determine exact methods*/
	proc sql;
		select min (count) into : min0-:min1 from var&c group by &&cov&c..n order by &&cov&c..n;
	quit;

	proc freq data = adqs order=data;
		tables &&cov&c..n*expn / out = &&cov&c.._all relrisk ;
		where paramcd = upcase("&&cov&c");
	run;

	/*Create formatted values and CIs*/
	data &&cov&c.._rel (keep = &&cov&c..n expn sig value);
		length sig $40;
		set Strat&c;

		if index(table,'Table 1') then do;
			&&cov&c..n = 1;
			minobs = &min1;
		end;
		else do;
			&&cov&c..n = 0;
			minobs = &min0;
		end;

		expn = 1;

		if minobs >= 10 then sig = put(input(_RROR_,best.),5.2)||" ("||put(input(L_RROR,best.),5.2)||", "||put(input(U_RROR,best.),5.2)||")";
		else sig = put(input(_RROR_,best.),5.2)||"("||put(input(XL_RROR,best.),5.2)||", "||put(input(XU_RROR,best.),5.2)||")*";

		value = _rror_;
	run;

	proc sort data = &&cov&c.._rel;
		by &&cov&c..n expn;
	run;

	/*Get frequencies*/
	data &&cov&c..;
		merge var&c &&cov&c.._all (rename=(count=denom));
		by descending &&cov&c..n descending expn;
	
		values = put(count,5.)||" ("||put(100*count/denom,5.1)||")";

		outdisp = put(outn,&outcome.disp.);
	run;

	proc transpose data =&&cov&c.. out = &&cov&c.._t;
		by descending &&cov&c..n descending expn denom;
		var values;
		id outn;
		idlabel outdisp;
	run;

	proc sort data = &&cov&c.._t;
		by &&cov&c..n expn;
	run;

	/*Put together final covariate table*/
	data &&cov&c.._final;	
		length level $40;
		merge &&cov&c.._t (in=a)
		  	  &&cov&c.._rel (in=b)
	    ;
		by &&cov&c..n expn;

		exp = strip(put(expn,&exposure.disp.))||" (N="||strip(put(denom,best.))||")";

		level = strip(put(&&cov&c..n,&&cov&c..disp.));

		sortn = input(substr("&&cov&c",2),best.);

		sort2 = &&cov&c..n;
	run;

	proc sort data = &&cov&c.._final;
		by descending &&cov&c..n descending expn;
	run;

%end;

/*Set everything together*/
data strat;
	set
	%do n = 1 %to &maxcov;
		 &&cov&n.._final
	%end;
	;
	by sortn;
run;

%mend;
%strat;

/*Headers*/
data headers;
	set strat (keep = sortn);
	by sortn;
	if first.sortn;
	header = put(sortn,headers.);
run;


data strat1;
	merge strat (in=a)
		  headers (in=b)
	;
	by sortn;

	ord + 1;

	sort_fin = (sort2=0);

run;

ods tagsets.rtf file = "&direc\Reports\table3.rtf" options(continue_tag="no") style=newrtf;
ods listing close;
title justify = center "&title3";
proc report data = strat1 nowd headline missing
	style=[frame=hsides] split = "!" ; 

	column sortn header sort_fin level ord  exp ("&_line Prevalence" _1 _0) sig;

	define sortn / order order = internal noprint;
	define ord /   order order = internal noprint;
	define sort_fin / order order = internal noprint;

	define header   / order "Covariate" style(column)=[just=left cellwidth=1in vjust=bottom font_size=8.5pt]
		  								 		   style(header)=[just=left font_size=8.5pt];
	define level    / order "Covariate Level" style(column)=[just=left cellwidth=1in vjust=bottom font_size=8.5pt]
		  								 	   style(header)=[just=left font_size=8.5pt];
	define exp    / display "Exposure" style(column)=[just=left cellwidth=1.2in vjust=bottom font_size=8.5pt]
		  								 	  			    style(header)=[just=left font_size=8.5pt];
	define _1 	   / display  style(column)=[just=center cellwidth=0.7in vjust=bottom font_size=8.5pt]
		  									 style(header)=[just=center font_size=8.5pt];
	define _0	   / display  style(column)=[just=center cellwidth=0.7in vjust=bottom font_size=8.5pt]
		  											style(header)=[just=center font_size=8.5pt];
	define sig	   / display "Odds Ratio (95% CI)" style(column)=[just=left cellwidth=1.2in vjust=bottom font_size=8.5pt]
		  								 	  			    style(header)=[just=left font_size=8.5pt];

	compute after sortn; 
		line ' ';
	endcomp;

	%macro foot;
		%if %length(&footnote3) ^= 0 %then %do;
			footnote justify = center "&footnote3";
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
