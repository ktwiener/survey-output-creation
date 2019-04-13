*********************************************************************
*  Assignment:    Final Project                                   
*                                                                    
*  Description:   Final Project Creating Standard Tables
*
*  Name:          Catie Wiener
*
*  Date:          05/04/2018                                       
*------------------------------------------------------------------- 
*  Job name:      importEXCEL.sas
*
*  Purpose:       Imports Excel document storing titles, footnotes, and formatting
*
*  Language:      SAS, VERSION 9.4  
*
*  Input:         surveyinfo.xlsx
*
*  Output:        
*                                                                    
********************************************************************;

/*Create Overall Filter Information*/
proc import
    out = overall
    datafile = "&direc.\surveyinfo.xlsx"
    dbms = xlsx replace;
    sheet = "Overall";
run;

data _null_;
	set overall end = last;

	if upcase(scan(overall,1)) = 'DATE' then call symputx (scan(overall,1),input(value,yymmdd10.)); *Create date to keep surveys after;

	/*Separate out filter expressions to upcase*/
	else if upcase(overall) = 'FILTER' then do;
		do while (index(upcase(value),' AND ') > 0); *Keep looping for as many criteria;
			filtn + 1;
			call symputx (cats("filt",put(filtn,best.)),cats("upcase(",scan(value,1),")",scan(value,2,' '),upcase(substr(value,index(value,'=')+1,index(upcase(value),'AND')-index(upcase(value),'=')-2))));
			value = substr(value,index(upcase(value),'AND')+3);	*Trim string for the next loop through;
		end;
		if (index(upcase(value),' AND ') = 0) and not missing (value) then do;
			filtn + 1;
			call symputx (cats("filt",put(filtn,best.)),cats("upcase(",scan(value,1),")",scan(value,2,' '),upcase(substr(value,index(value,'=')+1))));
		end;
	end;

	else if upcase(overall) = 'COVARIATES' then do;
		call symputx ("allcov",tranwrd(value,',',' '));
		do while (index(upcase(value),',') > 0); *Keep looping for as many criteria;
			covn + 1;
			call symputx (cats("cov",put(covn,best.)),substr(value,1,index(value,',')-1));
			value = substr(value,index(value,',')+1);	*Trim string for the next loop through;
		end;
		if (index(upcase(value),',') = 0) then do;
			covn + 1;
			call symputx (cats("cov",put(covn,best.)),value);
		end;

	end;

	
	else call symputx (scan(overall,1),value);
	if last then do;
		call symputx ("maxfilt",filtn);	
		call symputx ("maxcov",covn);
	end;
run;

/*Create Title and Footnote Macro Variables*/
proc import
    out = titles
    datafile = "&direc.\surveyinfo.xlsx"
    dbms = xlsx replace;
    sheet = "TitleFootnote";
run;

data _null_;
	set titles;
	call symputx (cats("title",put(tableNum,best.)),title);
	call symputx (cats("footnote",put(tableNum,best.)),footnote);
run;

/*Create Header decodes*/
proc import
    out = headers
    datafile = "&direc.\surveyinfo.xlsx"
    dbms = xlsx replace;
    sheet = "Headers";
	getnames = Yes;
run;

data headers;
   set headers;
   start + 1;
   if FormatName = "Headers" then start = QuestionNumber;
   label = DisplayedHeader;
   fmtname = FormatName;
run;

proc format cntlin=headers;
run;

/*Formatting*/
proc import
    out = formats
    datafile = "&direc.\surveyinfo.xlsx"
    dbms = xlsx replace;
    sheet = "Formats";
	getnames = Yes;
run;

proc sort data = formats;
		by questionnum;
run;

data format_bin;
	set formats end = last;
	by questionnum;
	type = 'C';
	start = storedvalue;
	label = put(code,1.);
	fmtname = cats('q',put(questionnum,best.),'bin');
	if last.questionnum then do;
		hlo='O';
	end;
run;

proc format cntlin=format_bin;
run;

data formats_display;
   set formats;
   start = code;
   label = DisplayedValue;
   fmtname = cats('q',put(questionnum,best.),'disp');
run;

proc format cntlin=formats_display;
run;
