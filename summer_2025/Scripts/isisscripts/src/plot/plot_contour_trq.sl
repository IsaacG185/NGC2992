define plot_contour_trq(){
%%%%%%%%%%%%%%%%%%%%%%%%%%    
%!%+
%\function{plot_contour_trq}
%\synopsis{creates a contour plot out of the results from function
%    contour_trq.}
%\usage{plot_contour_trq(String_Type inputDir);}
%\qualifiers{
%\qualifier{out}{   post script outputname}
%\qualifier{image}{ fits image outputname}
%\qualifier{x}{     x label}
%\qualifier{y}{     y label}
%}
%\description
%       - \code{inputDir} directory where all torque job files are,
%                  created by function contour_trq.
%
%       Be aware of the issues with the torque (look at the description
%       of contour_trq function), as it may not have all bins^2
%       values, and hence give wrong contour plot.
%        
%       The default post script file name is cont_default.ps.
%       Output fits image file is cont_default.fits.
%
% EXAMPLE
%
%
%       plot_contour_trq("fileDirectory";out="my_out",x="x_lab",y="y_lab");
%
%       creates a plot "my_out.ps" with x-axis label named "x_lab" and y_axis
%       label named "y_lab".                   
%\seealso{contour_trq, missing_contour_trq}
%!%-
%%%%%%%%%%%%%%%%%%%%%%%%%%    
   variable inputDir=String_Type;
   variable tempOut="outTemp.txt";
   variable i=Int_Type;
   variable lines=String_Type;
   variable k=Int_Type;
   variable j;
   switch(_NARGS)
     { case 1 : (inputDir)=();}
     { help (_function_name() ); return;}
   
   
   %GET LINES AND SORT THEM
   system("ls $inputDir -1 > $tempOut"$); %get all output files to one file
   variable input=fopen("$tempOut"$,"r");
   lines=fgetslines(input);
   variable chose=[0:length(lines)-2:1];
   lines=lines[chose];
   variable sout=fopen("test.txt","w");
   variable binsSq=sqrt(length(lines));

   %IF ALL NEEDED VALUES ARE CALCULATED OR SOME ARE MISSING
   variable nonZeroDigit=strchop(string(binsSq),'.',0);   %check if number of lines is bins^2
   if(strcmp(nonZeroDigit[1],"0")){%
      ()=fprintf(stdout,"======================\nYou do not have all contour_plot values! Your plot is wrong!\nCheck description of contour_trq function.\nYou may need to run missing_contour_trq function.\n======================\n");
       help (_function_name() );
   }
   binsSq=int(binsSq);
   
   %IF ARRAY HAS NEGATIVE FIRST VALUES
   variable neg=where(strncmp(lines,"-",1)==0); %negative starting numbers
   if(length(neg)!=0){%
      %POS:
      variable pos=where(strncmp(lines,"-",1)!=0); %positive starting numbers
      variable posArr=lines[pos];%all positive lines
      %NEG:
      neg=reverse(neg);
      variable negArr=lines[neg];%all negative lines
      variable start=0;
      variable bins=binsSq;
      variable tempo;
      
      _for j(0,(length(neg)/binsSq)-1,1){
	 variable binPart=[start:bins-1:1];
	 variable neg_temp_Arr=negArr[binPart];
	 neg_temp_Arr=reverse(neg_temp_Arr);
	 ifnot(start){
	    tempo=[neg_temp_Arr];
	 }else{
	    tempo=[tempo,neg_temp_Arr];
	 }
	 start=start+binsSq;
	 bins=bins+binsSq;
      }
      variable negArr_1=@tempo;
      lines=[negArr_1,posArr];
   }else{
      variable sorted=array_sort(lines);
      lines=lines[sorted];
   }

   %SORTED TABLE TO FITS FILE
   variable arr_temp=Double_Type[length(lines)];
   variable arr_x=Double_Type[length(lines)];
   variable arr_y=Double_Type[length(lines)];
   variable arr=Double_Type[binsSq,binsSq];
   variable best_chi_value=1e5;
   _for i(0,length(lines)-1,1){	    
      variable partLines=strchop(lines[i],'_',0);
      lines[i]=strtrans(lines[i],"\n","");
      variable chiFile=fopen(inputDir+"/"+lines[i],"r");
      
      variable chiLine=fgetslines(chiFile);
      k=0;
      while(k<length(chiLine)){%
	 if(string_matches(chiLine[k],"Chi",1)!=NULL){
	    variable chi=strchop(chiLine[k],'=',0);
	    break;
	 }
	 k++;
      }
      arr_temp[i]=atof(chi[1]);
      if(arr_temp[i] < best_chi_value){%
	 best_chi_value=arr_temp[i];
	 variable best_x=atof(partLines[0]);
	 variable best_y=atof(partLines[1]);
      }
      
      arr_x[i]=atof(partLines[0]);
      arr_y[i]=atof(partLines[1]);
      ()=fclose(chiFile);
   }

   %PART ARRAY TO bins * bins
   variable x,y;
   variable b=0;
   _for x(0,binsSq-1,1){%
      _for y(0,binsSq-1,1){%
	 arr[y,x]=(arr_temp[b]-min(arr_temp));
	 b++;
      }
   }
   system("rm $tempOut"$);
   ()=fclose(input);

   %CREATE FITS IMAGE
   fits_write_image("test.fits",arr);
   variable fd=fits_open_file("test.fits","wr");
   ()=fprintf(stdout,"Best minimum value is %f.\n",best_chi_value);
   fits_update_key(fd,"BESTSTAT",best_chi_value);%min(arr_temp));
   fits_update_key(fd,"BEST_X",best_x);
   fits_update_key(fd,"BEST_Y",best_y);
   fits_update_key(fd,"PXMIN",min(arr_x));
   fits_update_key(fd,"PXMAX",max(arr_x));
   fits_update_key(fd,"PXNUM",binsSq);
   fits_update_key(fd,"PYMIN",min(arr_y));
   fits_update_key(fd,"PYMAX",max(arr_y));
   fits_update_key(fd,"PYNUM",binsSq);
   fits_close_file(fd);

   variable image=load_conf("test.fits");

   variable outputImage=qualifier("image",NULL);
   if(outputImage!=NULL){
      save_conf(image,outputImage+".fits");
   }else{
      save_conf(image,"cont_default.fits");
   }
   
   %save_conf(image,"cont_default.fits");
   variable outputname=qualifier("out",NULL);
   if(outputname!=NULL){
      open_plot(outputname+".ps/cps");
   }else{
      open_plot("cont_default.ps/cps");
   }
   variable xlab=qualifier("x",NULL);
   variable ylab=qualifier("y",NULL);
   if(xlab!=NULL){
      xlabel(xlab);
   }
   if(ylab!=NULL){
      ylabel(ylab);
   }
   plot_conf(image);
   ()=close_plot;
}
