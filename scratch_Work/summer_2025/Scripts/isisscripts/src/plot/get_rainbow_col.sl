require( "xfig");
require( "rand" );
require( "png");

private define get_col_map()
{
   variable R = ([0:255])/255.;
   variable G = [0:255]/255.;
   variable B = [0:255]/255.;
   R = ad_colormap_gauss(0.6,R,0.3) +ad_colormap_gauss(1,R,0.3)*1.3 + 
     ad_colormap_gauss(0.47,R,0.13)/3;
   B = ad_colormap_gauss(0.2,B,0.2)+ad_colormap_gauss(0.08,B,0.07)/3;
   G = ad_colormap_gauss(0.95,G,0.3) + ad_colormap_gauss(0.21,G,0.12)/3;
   
   
   
   variable RI,GI,BI;
   RI = ad_colormap_norm_col(R);
   GI = ad_colormap_norm_col(G)*19/20;
   BI = ad_colormap_norm_col(B)*3/4;
   png_add_colormap("td_2d_rainbow", ((RI << 16) | (GI << 8) | BI ));
   
%   variable col_map = png_get_colormap("td_2d_rainbow");   
   
   return "td_2d_rainbow";
   
}

%%%%%%%%%%%%%
define get_rainbow_col(i,num)
%%%%%%%%%%%%%
%!%+
%\function{get_rainbow_col}
%\synopsis{get a rainbow color}
%\usage{color = get_rainbow_col(Integer_Type value, Integer_Type num_colors);}
%\description
%  The value has to be within [0:num_colors-1], to get the correct
%  color here.
%\seealso{xfig_new_color}
%!%-
{

   if (i > (num-1)) return "black";
   
   variable col_map = png_get_colormap(qualifier("col_map",get_col_map()));
    variable fnum,fname;
    if (qualifier_exists("linear_numbers")) {
	fnum=i;
    } else {
	fnum = rand();
    }
   fname="td_rainbow"+string(fnum);
   xfig_new_color(fname,col_map[nint(((i*1.)*255)/(num-1))];);
   
  return fname;
}
