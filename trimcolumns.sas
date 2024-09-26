%macro trimcolumns(in=,out=);
	options varlenchk=nowarn;

	%if %sysfunc(countw(&in,"."))=2 %then %do;
		%let libname = %scan(&in,1,".");
		%let memname = %scan(&in,2,".");
		%end;
	%else %do;
		%let libname = work;
		%let memname = &in;
		%end;

	proc sql noprint;
 	     select count(*) into :nobs from &in;
		 select count(*) into :ncharVar from sashelp.vcolumn where upcase(libname)=upcase("&libname") and upcase(memname)=upcase("&memname") and upcase(type)="CHAR";
	quit;

     %if &nobs > 0 and &ncharVar > 0 %then %do;
		  data _null_;
		       set &in;
		       array qqq(*) _character_;
		       call symput('siz',put(dim(qqq),5.-L));
		       stop;
		 run;

		 data _null_;
		       set &in end=done;
		       array qqq(&siz) _character_;
		       array www(&siz.);
		       if _n_=1 then do i= 1 to dim(www);
		       www(i)=0;
		       end;
		       do i = 1 to &siz.;
		       www(i)=max(www(i),length(qqq(i)));
		       end;
		       retain _all_;
		       if done then do;
		       do i = 1 to &siz.;
		            length vvv $50;
		            vvv=catx(' ','length',vname(qqq(i)),'$',www(i),';');
		            fff=catx(' ','format ',vname(qqq(i))||' '||
		       		compress('$'||put(www(i),5.)||'.;'),' ');
		            call symput('lll'||put(i,5.-L),vvv) ;
		            call symput('fff'||put(i,5.-L),fff) ;
		       end;
		       end;
		 run;

		 data &out(compress=yes);
		       %do i = 1 %to &siz.;
		       &&lll&i
		       &&fff&i
		       %end;
		 set &in;
		 run;
	 %end;
	 %else %do;
		data &out(compress=yes);
			set &in;
		run;
	 %end;

	options varlenchk=warn;

%mend;


/*Sample Call*/
/* %trimcolumns(in=work.tableA,out=lz.MyFinalTable); */
%trimcolumns(in=trim.hmeq,out=trim.hmeq_trim);

/* compare my original file size to the new table file size */

filename myfile '/export/viya/homes/john.doe@sas.com/data/hmeq.sas7bdat';

data fsize;
set sashelp.vextfl(where=(fileref='MYFILE'));
/* Calculate size in MB */
filesize=filesize/(1024**2);
call symputx('filesize',filesize);
run;

filename myfile '/export/viya/homes/john.doe@sas.com/data/hmeq_trim.sas7bdat';

data fsize2;
set sashelp.vextfl(where=(fileref='MYFILE'));
/* Calculate size in MB */
filesize=filesize/(1024**2);
call symputx('filesize',filesize);
run;

proc append base=fsize data=fsize2; run;
proc print data=work.fsize; var xpath filesize; run;

/* Optional step to load the data to CAS */
/* cas;
proc casutil incaslib="Public" outcaslib="Public";
	droptable casdata="hmeq_trim" quiet;
	load data="/export/viya/homes/john.doe@sas.com/data/hmeq_trim" casout="hmeq_trim" promote;
    save casdata="hmeq_trim" casout="hmeq_trim" replace ;
run; */