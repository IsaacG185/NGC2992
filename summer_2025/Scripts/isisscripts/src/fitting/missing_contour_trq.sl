define missing_contour_trq(){
%%%%%%%%%%%%%%%%%%%%%%%%%%    
%!%+
%\function{missing_contour_trq}
%\synopsis{calculates remaining contour points from function
%    contour_trq. It is used in such cases where countour_trq does
%    finnished before all point are calculated due to torque
%    issues.} 
%\usage{missing_contour_trq(String_Type inputDir);}
%\description
%    -\code{inputDir}   directory where all torque job files are,
%                       created by function contour_trq
%
%    It may be required to run the function several times.
%    The output (number of files) needs to be checked manualy.
%\example           
%    missing_contour_trq("torqueFiles");
%          
%\seealso{contour_trq}
%!%-
%%%%%%%%%%%%%%%%%%%%%%%%%%    
   
   variable inDir=String_Type;
   variable infile2=String_Type;
   variable i,j,k,in_1,in_2,lines_1,lines_2;
   variable part_1,part_2;
   variable wallTime=qualifier("walltime","00:30:00");

   switch(_NARGS)
     { case 1 : (inDir)=();}
     { help (_function_name() );return;}
   
   variable out="torque.missing.txt";
   
   system(sprintf("ls %s/Files/*trq | xargs -n1 basename \> temp1.txt ",inDir));
   system(sprintf("ls %s/*trq | xargs -n1 basename \> temp2.txt",inDir));
   system("diff -w -y --suppress-common-lines temp1.txt temp2.txt \> temp.out");


   variable tempIn=fopen("temp.out","r");
   variable tempOut=fopen(out,"w");
   variable newLine, outNew;
   lines_1=fgetslines(tempIn);
   
   _for i(0,length(lines_1)-1,1){%
	    newLine=strchop(lines_1[i],'_',0);
	    outNew=sprintf("%s_%s_trq \n",newLine[0],newLine[1]);
	    outNew=strtrim(outNew,"\n");
	    ()=fprintf(tempOut,"isis %s/Files/%s\n",inDir,outNew);
   }

   ()=fclose(tempIn);
   ()=fclose(tempOut);
   system(sprintf("qsub_array %s  --walltime=$wallTime --arch=x86_64 --pretend",out));
   ()=fprintf(stdout,"Wrote %d jobs to %s.\n",length(lines_1),out);
   system("rm temp1.txt temp2.txt temp.out");
}
