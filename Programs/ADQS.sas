*********************************************************************
*  Assignment:    Final Project                                   
*                                                                    
*  Description:   Final Project Creating Standard Output for Qualtrics Surveys
*
*  Name:          Catie Wiener
*
*  Date:          05/04/2018                                       
*------------------------------------------------------------------- 
*  Job name:      ADQS.sas
*
*  Purpose:       Creates Analysis Dataset from the Survey
*
*  Language:      SAS, VERSION 9.4  
*
*  Input:         survey.csv
*
*  Output:        ADQS SAS dataset
*                                                                    
********************************************************************;

/***************************************/
/*		Importing All Data			   */
/***************************************/

/*Import Survey*/
proc import datafile = "&direc.\Data\survey.csv" out = _surv
	dbms =  CSV REPLACE; 
	getnames = yes; 
run;

/*Create Look-Up Table of STEM Majors*/
proc iml;
    submit / R;
            library(XML)
            url <- "https://www.nafsa.org/Resource_Library_Assets/Regulatory_Information/DHS_STEM_Designated_Degree_Program_List_2012"      
		    page <- htmlTreeParse(readLines(url), useInternalNodes=T)
            table1 <- readHTMLTable(page)
    endsubmit;

	Call ImportDatasetFromR("Work.STEMList", "table1");

 quit;

/*Create Look-up Table of Department Codes at UNC*/
 
filename CODE url "http://www.catalog.unc.edu/courses/";

data maj_codes (keep = major code);
     length code $200 ;
     infile code length=len lrecl=32767;
     input line $VARYING32767. len;
	 if _n_<100 then put line= ;

	 retain start;
	 if index(line,'<div id="atozindex">') then start = 1;
	 if index(line,'</div>') then start = 0;

	 if start = 1 and index(line,'/courses/') then  do;
		code = scan(scan(line,3,'<>'),-1);
		major = substr(scan(line,3,'<>'),1,index(scan(line,3,'<>'),'(')-1);
		output;
	end;
 run;


/***************************************/
/*  		Filtering Survey Data	   */
/***************************************/

data labels surv;
	set _surv;
	
	if _n_ = 1 then output labels;  /*Create Dataset that Holds Questions*/
	else if _n_ > 2  then output surv; /*Output Survey Responses*/
run;

/*Create labels for future parameters*/
proc transpose data = labels out = lab_t (rename=(_name_=paramcd col1=param) where=(index(paramcd,'_')=0));
	var q:;
run;

/*Create analysis date and subject id*/
data surv1_;
	format adt date9.;
	set surv;

	ADT = input(scan(recordeddate,1,' '),yymmdd10.); /*Create Analysis Date*/

	USUBJID + 1; /*Create Unique Subject ID*/

run;

/***************************************/
/*  	Assigning STEM vs Non-STEM	   */
/***************************************/
/*Gets rid of Peace War and Defense & MEJO Majors because of all the pesky commas & Know they are not STEM*/
data surv1;
	set surv1_ ;

	%macro nostem (val1=,val2=);
		if index(upcase(strip(Q4)),"&val1")=1 then q4 = substr(q4,index(upcase(q4),"&val2")+length("&val2")+1);
		else if index(upcase(strip(Q4)),"&val1")>1 then q4 = substr(q4,1,index(upcase(q4),"&val2")-1);
	%mend;
	%nostem (val1=PEACE,val2=DEFENSE);
	%nostem (val1=MEDIA,val2=JOURNALISM);
	%nostem (val1=MEDIA,val2=AND);
	if index(upcase(q4),'AND ')=1 then q4 = substr(q4,5);
run;

data surv_filt;
	set surv1;
	/*Apply Filter criteria to dataset*/
	%macro setfile;
		if upcase(finished) ^= 'FALSE' 
			%if &date ^=  %then %do;
				and adt > &date
			%end;
			%if &maxfilt ^=  %then %do i = 1 %to &maxfilt;
				and &&filt&i
			%end;
		;
	%mend;
	%setfile;

	/*Separate Out Double Majors*/
	%macro doubles (join=);
		if index(upcase(q4),"&join") then do;
			q4_1 = substr(q4,1,index(upcase(q4),"&join")-1);
			q4_2 = tranwrd(upcase(substr(q4,index(upcase(q4),"&join"))),"%trim(&join) "," ");
		end;
	%mend;
	%doubles (join=%str(,))
	else %doubles (join=AND)
	else %doubles (join=&)
	else %doubles (join=+)
	else q4_1 = q4;

	array majors (*) q4_1 - q4_2;
	do i = 1 to 2;	
		/*Get rid of BA and BS at end of majors*/	
		if prxmatch(prxparse("/BA|BS|B.A.|B.S./"),scan(majors(i),-1,' ')) then majors(i) = substr(majors(i),1,index(majors(i),scan(majors(i),-1,' '))-1);

		/*Removes Lingering Commas*/
		if index(majors(i),',')=1 then majors(i) = substr(majors(i),2);
	end;
run;

/*Classify Major as STEM vs. non-STEM by using Webscraped Data*/

proc sql;
	/*Match up reported codes (incorrect and correct) to corresponding UNC major*/
	create table surv_filt1 as
	select a.*
		  ,b.*
	from surv_filt as a left join maj_codes as b
		on strip(upcase(a.q4_1))=b.code or strip(upcase(a.q4_2))=b.code
		or upcase(a.q4_1)=substr(b.code,1,3) or upcase(a.q4_2)=substr(b.code,1,3)
	order by usubjid
	;

quit;

/*Make sure listed double majors are matched up correctly and separated after checking UNC codes*/
data surv_filt2;
	length major1 major2 $30;
	set surv_filt1;
	by usubjid;
	if substr(upcase(q4_1),1,3) = substr(code,1,3) and not missing (code) then do;
		q4_1 = major;
		call missing (q4_2);
	end;
	else if substr(upcase(q4_2),1,3) = substr(code,1,3) and not missing (code) then do;
		q4_2 = major;
		call missing (q4_1);
	end;

	retain major1 major2 ;

	if first.usubjid then do;
		major1 = '';
		major2 = '';
	end;
	if not missing (q4_1) then major1 = q4_1;
	if not missing (q4_2) then major2 = q4_2;

	if last.usubjid;

run;

/*Stack all types of majors into one variable*/
data allmajs;
	set surv_filt2 (rename=(major1=allmajor))
		surv_filt2 (rename=(major2=allmajor))
		;
	allmajor = strip(upcase(allmajor));
	keep allmajor;
run;

/*Merge with Webscraped STEM majors to start Look-up table*/
proc sql;
	create table maj_lup as
	select distinct allmajor
		  ,NULL_Numeric__Order_CIP_Code__Ti as stems
		  ,'STEM' as IND length = 8
	from allmajs, stemlist
	where prxmatch(prxparse("/MANAGEMENT|POLITICAL|COMMUNICATION/"),strip(allmajor))=0 and not missing (allmajor) 
	having index(upcase(stems),upcase(allmajor)) > 0 or index(allmajor,'SCIENCE');
	;
quit;

proc sort data = maj_lup nodupkey;
	by allmajor;
run;


/*Finally Assigning Major Type*/
proc sql;
	create table surv_filt_fin as
	select a.*,
		   b.*
	from surv_filt2 as a left join maj_lup as b
	on strip(upcase(major1))=allmajor or strip(upcase(major2))=allmajor
	order by usubjid
	;
quit;

data survey;
	length major $8;
	set surv_filt_fin (drop = major q4_:);
	by usubjid;
	if last.usubjid;

	if not missing (ind) then q4 = 'STEM';
	else q4 = 'Non-STEM';


run;


/***************************************/
/*  	Creating Long DS for Tables	   */
/***************************************/
/*Consolidate Free-form Answers into "Other" & Maintaining original answers for listings*/

proc transpose data = survey out = multqs (rename=(col1=AVALC));
	by usubjid adt &exposure &outcome &allcov;
	var q:;
run;

/*Create numeric version of question for sorting and merging*/
data multqsT;
	set multqs;
	by usubjid;
	where not missing (avalc);
	paramcd = upcase(_name_);
	if index(paramcd,'_') then paramn = input(substr(paramcd,2,index(paramcd,'_')-2),best.);
	else paramn = input(substr(paramcd,2),best.);

run;

proc sort data = multqst;
	by usubjid paramn ;
run;

/*Store details in an extra variable and make all parameters consistent*/
data adqs_t;
	set multqst;
	by usubjid paramn;
	retain avalcTEMP;

	if first.paramn then avalcTEMP = avalc;
	else avalcTEMP = catx(', ',avalcTEMP, avalc);

	if index(avalctemp,',') then do;
		DETAILS = avalctemp;
		avalc = "Other";
	end;
	else avalc = avalctemp;

	paramcd = scan(paramcd,1,'_');
	if last.paramn;
run;

/*Get parameter names*/
proc sql;
	create table adqs_1 as
	select a.*,
		   b.param
	from adqs_t as a left join lab_t as b
	on a.paramcd=b.paramcd
	order by usubjid, paramn
	;
quit;

/*Final clean-up*/
data ds.adqs (label = "Survey Data");
	retain USUBJID %upcase(&ALLCOV) %upcase(&EXPOSURE) %upcase(&OUTCOME) ADT PARAM PARAMCD PARAMN AVALC DETAILS;
	set adqs_1;

	label USUBJID = 'Unique Subject Identifier'
		  ADT     = 'Analysis Date'
		  PARAM   = 'Parameter'
		  PARAMCD = 'Paramter Code'
		  PARAMN  = 'Parameter (N)'
		  AVALC   = 'Analysis Value (C)'
		  DETAILS = 'Analysis Details'
		  &EXPOSURE = 'Exposure'
		  &OUTCOME  = 'Outcome'
		  %macro covs;
		  	%do i = 1 %to &maxcov;
				&&COV&I = "Covariate &i"
			%end;
		 %mend;
		 %covs
		;

	keep USUBJID &ALLCOV &EXPOSURE &OUTCOME ADT PARAM PARAMCD PARAMN AVALC DETAILS;
run;

