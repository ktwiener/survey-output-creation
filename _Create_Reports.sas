*********************************************************************
*  Assignment:    Final Project                                   
*                                                                    
*  Description:   Final Project Creating Standard Tables
*
*  Name:          Catie Wiener
*
*  Date:          05/04/2018                                       
*------------------------------------------------------------------- 
*  Job name:      _Create_Report.sas
*
*  Purpose:       Calls all programs to generate tables
*
*  Language:      SAS, VERSION 9.4  
*
*  Input:         surveyinfo.xlsx
*
*  Output:        
*                                                                    
********************************************************************;

/*Use Current Directory Path*/
filename dummy '.';
%let direc=%sysfunc(pathname(dummy));

libname ds "&direc.\Data";

%include "&direc.\Programs\importEXCEL.sas";

%include "&direc.\Programs\adqs.sas";

%include "&direc.\Programs\template.sas";

%include "&direc.\Programs\Table1.sas";

%include "&direc.\Programs\Table2.sas";

%include "&direc.\Programs\Table3.sas";
