
%%%%%%%%%%%%%%%%%%%%%%%%%%%    
define contour_trq(){
%%%%%%%%%%%%%%%%%%%%%%%%%%    
%!%+
%\function{contour_trq}
%\synopsis{creates and (with qualifier trq) sends bins^2 jobs to torque (at Remeis cluster) and
%        calculates chi_2 values for each point for chosen 2 parameters.}
%\usage{contour_trq(String_Type inputPar1, inputPar2, Int_Type bins,
%        Double_Type lowLimPar1, upLimPar1,lowLimPar2, upLimPar2,
%        String_Type startUpFile [, parFile], outDir, time);}  
%\qualifiers{
%\qualifier{trq}{Sends the jobs to Remeis torque}
%}
%
%\description
%    - \code{inputPar1}     input parameter 1 written as in .par file
%    - \code{inputPar2}     input parameter 2 written as in .par file
%    - \code{bins}          number of chosen bins
%    - \code{lowLimPar1}    lower parameter 1 value
%    - \code{upLimPar1}     upper parameter 1 value
%    - \code{lowLimPar2}    lower parameter 2 value
%    - \code{upLimPar2}     upper parameter 2 value
%    - \code{startUpFile}   upload file (with data, binning,
%                                 noticing etc.)
%    - \code{parFile}       best fit parameter file name (optional) 
%    - \code{outDir}        output directory for torque files and
%                                 calculated output files
%    - \code{time}          torque wall time
%
%    In case where values for all bins^2 points are not calculated (for
%    example when the torque walltime is shorter than needed), one can run
%    function missing_contour_trq in order to get all bins^2 values. 
%    
%    To plot the result use the function plot_contour_trq.
%
%
% EXAMPLE
%
%   contour_trq(`relconv(1).Incl`,`reflionx(1).Xi`,32,25,35,1000,4000,"data.sl",
%   "results/bestFit.par","outputInclXi","02:00:00";trq);
%
%   will calculate 32 by 32 values for two parameters and write the
%   output files to "outputInclXi" subdirectory. It will do that by
%   sending the 32x32 jobs to Remeis torque via qualifier "trq", and
%   giving it a walltime of 02:00:00 hours. 
%   
%\seealso{missing_contour_trq, plot_contour_trq}
%!%-
%%%%%%%%%%%%%%%%%%%%%%%%%%    

   variable i=Int_Type;
   variable j=Int_Type;
   variable par1=String_Type;
   variable par2=String_Type;
   variable bins=Int_Type;
   variable par1Low=Double_Type;
   variable par1High=Double_Type;
   variable par2Low=Double_Type;
   variable par2High=Double_Type;
   variable loadData=String_Type;
   variable loadPar=String_Type;
   variable outDir=String_Type;
   variable walltime=String_Type;
   
   switch(_NARGS)
     {case 10: (par1,par2,bins,par1Low,par1High,par2Low,par2High,loadData,outDir,walltime)=(); }    
     {case 11: (par1,par2,bins,par1Low,par1High,par2Low,par2High,loadData,loadPar,outDir,walltime)=(); }
     {help (_function_name());return;}
   

   variable xbins=[par1Low:par1High:#bins];
   variable ybins=[par2Low:par2High:#bins];

   ()=system("mkdir $outDir"$);
   variable files=outDir+"/Files";
   ()=system("mkdir $files"$);

   variable par1_out=strchop(par1,'.',0);
   variable par2_out=strchop(par2,'.',0);
   variable outFile=par1_out[1]+"_"+par2_out[1]+".trqFile";
   variable trqFile=fopen(outFile,"w");


   _for i(0,length(xbins)-1,1){
      _for j(0,length(ybins)-1,1){
	 variable str_x=sprintf("%012.8f",xbins[i]);
	 variable str_y=sprintf("%012.8f",ybins[j]);
	 
	 variable out=fopen(files+"/"+str_x+"_"+str_y+"_trq","w");
	
	 ()=fprintf(trqFile,"isis "+files+"/"+str_x+"_"+str_y+"_trq\n");
	 
	 ()=fprintf(out,"require(\"isisscripts\");\n");
	 ()=fprintf(out,"evalfile(\"$loadData\");\n"$);
	 if (is_defined("loadPar")==0)  message("No parameter file given! loadData must load the parameters instead!");
	 else ()=fprintf(out,"load_par(\"$loadPar\");\n"$);
	 ()=fprintf(out,"set_par(\"$par1\",%.8f,1);\n"$,xbins[i]);
	 ()=fprintf(out,"set_par(\"$par2\",%.8f,1);\n"$,ybins[j]);
	 ()=fprintf(out,"fit_counts;\n");
	 ()=fprintf(out,"save_statistics(\"%s/%012.8f_%012.8f_trq\");\n \n",outDir,xbins[i],ybins[j]);
	 ()=fprintf(out,"exit;\n");
	 ()=fclose(out);
      }
   }
   ()=fclose(trqFile);
   if(qualifier_exists("trq")){
      ()=system("qsub_array $outFile --walltime=$walltime --arch=x86_64"$);
   }
}

