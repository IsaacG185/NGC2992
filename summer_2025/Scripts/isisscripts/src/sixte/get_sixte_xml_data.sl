% -*- mode: slang; mode: fold -*-

private define file2string( filename ){ %{{{
    % this function reads a textfile into a string and returns it
    variable fp = fopen(filename,"r");
    variable output = "";
    variable buffer;
    while(fgets(&buffer,fp) != -1){
          output += buffer;
    }
    () = fclose(fp);
    return(output);
}
%}}}
private define searchkey( text, element, attribute ){ %{{{
  % read an xml key, given the name of the element and attribute
  % this is still seriously limited - only do this if you know what you're doing
  % returns an empty string if nothing is found
  variable i_start,i_stop,pos,len;
  variable key = element+".*\n?[^>]*"R+attribute;
  variable expr = sprintf("\(%s=\"[^\"$]*\"\)"R,key);
  % what this expression does: first find the line where the element appears
  % then find whether the attribute appears in any of the following lines, but
  % still inside the tag (hence the [^/]*)
  % the value is then behind the attribute after an = sign and in quotes
  % with no further quotes or line-breaks inbetween
  if (string_match(text,expr)){
    (pos,len) = string_match_nth(1);
  } else {
    return(""); % nothing has been found
  }
  %i_stop is the last index before the closing quote character
  i_stop = pos + len -2;
  % count backwards until you find the opening quote character
  i_start = i_stop+1;
  do {
    i_start -= 1;
  } while (strncmp(text[[i_start-1]],"\"",1));
  %i_start = pos + strlen(key)+2;

  variable ret = text[[i_start:i_stop]];

  if( strlen(ret) == 0 ){
    vmessage(" ERROR(%s): XML has no attribute '%s' in element '%s'! Aborting ...",
	     _function_name, attribute, element
	    );
    exit;
  }
  return ret;
}
%}}}

define get_sixte_xml_data( xmlfile ){ %{{{
%!%+
%\function{get_sixte_xml_data}
%\synopsis{Loads a SIXTE XML file and outputs their attributes and values}
%\usage{Struct_Type xmlinfo = get_sixte_xml_data(String_Type filename);}
%\notes
%    This function currently only supports XMLs of the Athena WFI and
%    eROSITA missions.
%!%-
  
  %% check xml access
  if( access( xmlfile, F_OK )!= 0 ){
    vmessage(" ERROR(%s): XML '%s' is not accessible! Aborting ...",
	     _function_name, xmlfile
	    );
    exit;
  }
  variable xmldir  = path_dirname(xmlfile)+"/";
  variable xmltext = file2string( xmlfile );

  variable telescop = searchkey( xmltext, "instrument", "telescop" );
  variable instrume = searchkey( xmltext, "instrument", "instrume" );
  variable arffile  = searchkey( xmltext, "arf", "filename" );
  variable rmffile  = searchkey( xmltext, "rmf", "filename" );
  variable psffile  = searchkey( xmltext, "psf", "filename" );
  variable pirmffile= searchkey( xmltext, "pirmf", "filename" );
  variable pha2pifile= searchkey( xmltext, "pha2pi", "filename" );
  variable vigfile  = searchkey( xmltext, "vignetting", "filename" );
  variable enthresh = atof(searchkey( xmltext, "threshold_readout_lo_keV", "value" ));
  variable xwidth   = atoi(searchkey( xmltext, "dimensions", "xwidth" ));
  variable ywidth   = atoi(searchkey( xmltext, "dimensions", "ywidth" ));
  variable xdelt    = atof(searchkey( xmltext, "wcs", "xdelt" ));
  variable ydelt    = atof(searchkey( xmltext, "wcs", "ydelt" ));
  variable xrpix    = atof(searchkey( xmltext, "wcs", "xrpix" ));
  variable yrpix    = atof(searchkey( xmltext, "wcs", "yrpix" ));
  variable xrval    = atof(searchkey( xmltext, "wcs", "xrval" ));
  variable yrval    = atof(searchkey( xmltext, "wcs", "yrval" ));
  variable rota     = atof(searchkey( xmltext, "wcs", "rota" ));
  variable focallen = atof(searchkey( xmltext, "focallength", "value" ));
  variable fov      = atof(searchkey( xmltext, "fov", "diameter" ));

  
  variable xmldata = struct{
    xmldir  = xmldir,
    xmlfile = xmlfile,
    mission = telescop,
    instrument = instrume,
    arffile     = xmldir+"/"+arffile, % Filename of ARF (string)
    psffile     = xmldir+"/"+psffile, % Filename of PSF (string)
    vigfile     = xmldir+"/"+vigfile, % Filename of VIGNETTING (string)
    rmffile     = xmldir+"/"+rmffile, % Filename of nominal RMF (string)
    eboundsfile = xmldir+"/"+rmffile, % Filename of nominal RMF (string)
    pirmffile   = xmldir+"/"+pirmffile, % Filename of PI RMF (string)
    pha2pifile  = xmldir+"/"+pha2pifile, % Filename of Pha2Pi correction (string)
    loenthresh = enthresh, % Lower Energy Threshold [keV]
    xnumpix = xwidth,
    ynumpix = ywidth,
    xdelt   = xdelt,
    ydelt   = ydelt,
    xrpix   = xrpix,
    yrpix   = yrpix,
    xrval   = xrval,
    yrval   = yrval,
    rota    = rota,
    focallen=focallen,
    fov     = fov,
    
    %% derived quantities( ATTENTION X/Y WIDTH is changed to mm!!!)
    xwidth  = xwidth * xdelt * 1e3, % Detector width in x direction [mm]
    ywidth  = ywidth * ydelt * 1e3, % Detector width in y direction [mm]
    x0      = xwidth * xdelt * 1e3 * (-0.5), % Origin shift in x direction [mm]
    y0      = ywidth * ydelt * 1e3 * (-0.5), % Origin shift in y direction [mm]
  };
  
  return xmldata;
}
%}}}

