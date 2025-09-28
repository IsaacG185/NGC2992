%%%%%%%%%%%%%%%%%%%%%%%
define sixte_psfgen(hew, npix, resolution_meter, focallength, filename){ %{{{
%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{sixte_psfgen(hew, npix, resolution_meter, focallength, filename)}
%\synopsis{simple wrapper to Sixte-Tool "psfgen"}
%\description
%   hew: HEW of PSF [arcsec]
%   npix: Number of pixels in X and Y direction
%   resolution_meter: width of one pixel in the focal plane [meter]
%   focallength: focal length of telescope [meter]
%   filename: name of output file
%   
%   Note: this functions requires Sixte to be installed!
%!%-


       variable command="psfgen "+
       			sprintf("Width=%d ", npix)+
			sprintf("PixelWidth=%e ", resolution_meter)+
			sprintf("FocalLength=%f ", focallength,)+
			sprintf("PSFFile=%s ", filename)+
			sprintf("HEW=%f ", hew)+
			"type=1 history=true";

   if (qualifier_exists("verbose"))  {
      message(command);
   }
	()=system(command);
}
%}}}
