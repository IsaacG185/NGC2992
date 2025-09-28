require("fitswcs");

%!%+
%\function{get_map_value_at_position}
%\synopsis{Extract map value from ra/dec position}
%\usage{Double_Type value = get_map_value_at_position(map,ra,dec);}
%\qualifiers{
%\qualifier{verbose}{Output detector coordinates on display. Default: 0}
%}
%\description
%   This function returns the value of a map at a certain ra/dec position
%   using the wcs of that map. Ra/Dec coordinates must be given as
%   decimal numbers.
%\seealso{read_difmap_fits, fitswcs_get_img_wcs, wcsfuns_project}
%!%-
define get_map_value_at_position() {
  variable map,ra,dec;
  switch(_NARGS)
  { case 3: (map,ra,dec) = (); }
  { help(_function_name);return;}
  variable verbose = qualifier("verbose",0);
  variable s = read_difmap_fits(map);
  variable wcs = fitswcs_get_img_wcs (map);
  variable o_map = @(s.img);
  variable pos_x,pos_y;
  (pos_x,pos_y) = wcsfuns_project (wcs, ra,dec);
  if (verbose == 1) vmessage("detector coordinates: x=%.2f y=%.2f",pos_x,pos_y);
  
  return o_map[int(pos_x),int(pos_y)];
}
