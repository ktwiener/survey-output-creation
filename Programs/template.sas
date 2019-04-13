*********************************************************************
*  Assignment:    Final Project                                   
*                                                                    
*  Description:   Final Project Creating Standard Tables
*
*  Name:          Catie Wiener
*
*  Date:          05/04/2018                                       
*------------------------------------------------------------------- 
*  Job name:      template.sas
*
*  Purpose:       Creates RTF template for outputs
*
*  Language:      SAS, VERSION 9.4  
*
*  Input:         
*
*  Output:        
*                                                                    
********************************************************************;

proc template;
   define style newrtf;
      parent=styles.rtf;
      style Table from output /
            Background=_UNDEF_
            Rules=groups
            Frame=void;
      style Header from Header /
            Background=_undef_;
      style Rowheader from Rowheader /
            Background=_undef_;
	  replace fonts /

      'CellFont'             = ("Times New Roman",10pt)

      'CellFont2'            = ("Times New Roman",9pt)

      'TitleFont2'           = ("Times New Roman",10pt,Bold)

      'TitleFont'            = ("Times New Roman",10pt,Bold)

      'StrongFont'           = ("Times New Roman",10pt,Bold)

      'EmphasisFont'         = ("Times New Roman",10pt,Italic)

      'FixedEmphasisFont'    = ("Times New Roman",10pt,Italic)

      'FixedStrongFont'      = ("Times New Roman",10pt,Bold)

      'FixedHeadingFont'     = ("Times New Roman",10pt,Bold)

      'BatchFixedFont'       = ("Times New Roman",10pt)

      'FixedFont'            = ("Times New Roman",10pt)

      'headingEmphasisFont'  = ("Times New Roman",10pt,Bold)

      'headingFont'          = ("Times New Roman",10pt,Bold)

      'docFont'              = ("Times New Roman",10pt);
    end;
run;

ods escapechar='^';

%let _line = %str(^R'\trowd\trleft\trql\brdrb\brdrs\sl-0 ');
%let st = style(column)=[just=center cellwidth=1in vjust=bottom font_size=8.5pt]
		  style(header)=[just=center font_size=8.5pt];


options missing=' ' options nodate nonumber mergenoby=WARN varinitchk=WARN orientation=portrait;
