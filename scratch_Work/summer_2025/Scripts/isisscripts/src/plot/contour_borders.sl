require( "gcontour" );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
define contour_borders()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{contour_borders}
%\synopsis{Returns outer borders of a contour}
%\usage{Double_Type[] = contour_borders(fits);}
%\qualifiers{
%\qualifier{conf_level [2]}{: set confidence level for which you need the borders}
%}
%\description
%   This function takes as input a contour in fits-format saved with
%   save_conf and returns the array [par1_min,par1_max,par2_min,par2_max].
%   Select the confidence level with the conf_level quelifier (1,2,3).
%\example
%   contour_borders("contour.fits";);
%\seealso{function_name2, function_name3}   
%!%-
{
  variable cont;
  switch(_NARGS)
  { case 1: cont = (); }
  { help(_function_name()); return; }

  variable conf_level = qualifier("conf_level",2);
  variable delta_chi;
  switch(conf_level)
  { case 1: delta_chi=2.3; }
  { case 2: delta_chi=4.61; }
  { case 3: delta_chi=9.21; }  
  
  variable c, line, cont_min, cont_max, p1_min, p1_max, p2_min, p2_max, stepx, stepy;
  
  c = load_conf (cont);
  line = gcontour_compute(c.chisqr,delta_chi);
  
  stepx = double(c.px.max - c.px.min)/c.px.num;
  stepy = double(c.py.max - c.py.min)/c.py.num;
  
  p1_min = c.px.min + (min(line[0].x_list[0])) * stepx;
  p1_max = c.px.min + (max(line[0].x_list[0])) * stepx;
  
  p2_min = c.py.min + (min(line[0].y_list[0])) * stepy;
  p2_max = c.py.min + (max(line[0].y_list[0])) * stepy;
  
  return [p1_min,p1_max,p2_min,p2_max];
}
