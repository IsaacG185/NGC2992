%%%%%%%%%%%%%%%%%%%%%%%
define sixte_create_img_xifu(ra,dec,fevt,fimg){
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{sixte_create_img_xifu}
%\synopsis{returns cmd to create an Image from an EventFile for the XIFU Baseline config }
%\usage{String cmd = sixte_create_img_xifu(double ra, double dec, string event_file, string image_file);}
%!%-
   return
     "imgev " +
     "EventList=$fevt "$ +
     "Image=$fimg "$ +
     "CoordinateSystem=0 " +
     "Projection=TAN " +
     "CUNIT1=deg CUNIT2=deg " +
     "NAXIS1=60 NAXIS2=64 " +
     sprintf("CRVAL1=%lf CRVAL2=%lf ", ra, dec) +
     "CDELT1=-0.001265 CDELT2=0.001265 " +
     "CRPIX1=32.5 CRPIX2=32.5 " +
     "clobber=yes ";
}


%%%%%%%%%%%%%%%%%%%%%%%
define sixte_create_img_wfi(ra,dec,fevt,fimg){
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{sixte_create_img_wfi}
%\synopsis{returns cmd to create an Image from an EventFile for the XIFU Baseline config }
%\usage{string cmd = sixte_create_img_wfi(double ra, double dec, string event_file, string image_file);}
%\qualifiers{
%\qualifier{mode}{["large"]: change mode of the WFI}
%}
%!%-

   if (qualifier("mode","large") != "large"){
      message("Only *large* mode implemented for the WFI yet");
      return;      
   }
   
   return
     "imgev " +
     "EventList=$fevt "$ +
     "Image=$fimg "$ +
     "CoordinateSystem=0 " +
     "Projection=TAN " +
     "CUNIT1=deg CUNIT2=deg " +
     "NAXIS1=512 NAXIS2=512 " +
     sprintf("CRVAL1=%lf CRVAL2=%lf ", ra, dec) +
     "CDELT1=-0.000621 CDELT2=0.000621 " +
     "CRPIX1=256.5 CRPIX2=256.5 " +
     "clobber=yes ";
}
