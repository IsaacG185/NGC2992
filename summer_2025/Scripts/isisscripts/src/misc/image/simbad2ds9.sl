%% This function intends on converting a SIMBAD cone search list into
%% a DS9 region file. The input is an ASCII file.
%%
%% Author: Ole Koenig (ole.koenig@fau.de)
%% Date:   2019-10-17

require("strsplit.sl");
require("__push_array.sl");

public define simbad2ds9(){
%!%+
%\function{simbad2ds9}
%\synopsis{Converts a SIMBAD cone search ASCII file into a DS9 region
%    file (default outfile: "ds9.reg")}
%\qualifiers{
%\qualifier{radius}{circle radius (arcsec), default: 20arcsec}
%\qualifier{type}{regex to filter for source type, default ""}
%}
%\notes
%    See http://simbad.u-strasbg.fr/simbad/sim-display?data=otypes
%    for a list of type abbreviations
%\example
%    simbad2ds9("simbadascii.txt","output.reg" ; radius=10, type="HXB");
%\usage{simbad2ds9(String_Type filename, [String_Type outfile]);}
%!%-

  variable filename;
  variable outfile="ds9.reg";
  switch(_NARGS)
  { case 1: (filename) = (); }
  { case 2: (filename, outfile) = (); }
  { help(_function_name()); return; }

  %% Test whether file exists
  if ( system(sprintf("[ -f %s ]", filename)) != 0 ){
    vmessage("Input file does not exist");
  }
  
  %% Radius with which the circles are drawn (ideally this should be
  %% the 90% error radius of each measurement)
  variable radius = qualifier("radius", 20.0); % (arcsec)
  %% A regular expression to filter the list for specific type
  %% E.g. filter for HMX via "HMX"
  %% See http://simbad.u-strasbg.fr/simbad/sim-display?data=otypes
  variable type = qualifier("type", ""); % Reg. Expression
  
  variable fpIn = fopen(filename,"r");
  variable data = fgetslines(fpIn);

  variable fpOut = fopen(outfile,"w");
  %% Write header of DS9 region file
  ()=fputs("# Region file format: DS9 version 4.1\n",fpOut);
  ()=fputs("global color=green dashlist=8 3 width=1 font=\"helvetica 10 normal roman\" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1\n",fpOut);
  ()=fputs("fk5\n",fpOut);
 
  %% Define regular expression to format string
  % First four entries: # |   dist|identifier   |type
  variable p1="\(\d\) *| *\(\d+.\d+\)|\(.+ .+\)|\(.+\)"R;
  % Coordinates: |ra dec   |
  variable p2="|\(\d\{2\} \d\{2\} \d\{2\}\.\d+\) \(-?\d\{2\} \d\{2\} \d\{2\}\.?\d*\)"R;
  
  variable line;
  % Skip first 9 and last 3 lines
  _for line (0,length(data)-1,1) {
    variable query = string_matches(data[line], p1+p2) ;
    if (query==NULL) { continue; }
    
    variable out = struct {
      raw        = query[0],
      idx        = query[1],
      dist       = atof(query[2]),
      identifier = strtrim(query[3]),
      type       = query[4],
      %% Format R.A. and Dec. from "18 58 25.216" to "18:48:25.216"
      ra         = sprintf("%s:%s:%s", __push_array(strsplit(query[5]," "))),
      dec        = sprintf("%s:%s:%s", __push_array(strsplit(query[6]," ")))
    };

    if ( string_matches(out.type, sprintf(".*%s.*"R, type) )!=NULL ) {
      ()=fputs(sprintf("circle(%s,%s,%.2f\") # text={%s, %s}\n",
		       out.ra, out.dec, radius, out.identifier, out.type) ,fpOut);
    }
  }

  ()=fclose(fpIn);
  ()=fclose(fpOut);

}