%%%%%%%%%%%%%%%%%%%
define setPGPLOTenv()
%%%%%%%%%%%%%%%%%%%
%!%+
%\function{setPGPLOTenv}
%\synopsis{sets environment variables used by PGPLOT}
%\usage{setPGPLOTenv(Double_Type w, h[, hoff[, voff]]);}
%\qualifiers{
%\qualifier{gif}{sets the PGPLOT_GIF enviroment variables}
%}
%\description
%    The environment variables for the PGPLOT postscript driver,
%    \code{PGPLOT_PS_{WIDTH,HEIGHT,HOFFSET,VOFFSET}}, are set
%    to the specified width \code{w} and height \code{h}. The default
%    horizontal and vertical offset is \code{hoff=0} and \code{voff=0}.
%    The parameters \code{w}, \code{h}, \code{hoff}, \code{voff} specify the size in cm,
%    while the enviroment variables are measured in milli-inches.
%    
%    If the \code{gif} qualifier is given, \code{PGPLOT_GIF_{WIDTH,HEIGHT}}
%    are set to \code{w} and \code{h} (in pixels).
%\seealso{putenv, http://www.astro.caltech.edu/~tjp/pgplot/devices.html}
%!%-
{
  variable w=NULL, h=NULL, hoff=NULL, voff=NULL;
  switch(_NARGS)
  { case 0: ; }
  { case 2: (w, h) = (); }
  { case 3: (w, h, hoff) = (); }
  { case 4: (w, h, hoff, voff) = (); }
  { message("usage: setPGPLOTenv([w, h[, hoff[, voff]]]);"); }

  if(qualifier_exists("gif"))
  {
    if(w==NULL)  w = 800;
    if(h==NULL)  h = 600;
    putenv(sprintf("PGPLOT_GIF_WIDTH=%.0f", w));
    putenv(sprintf("PGPLOT_GIF_HEIGHT=%.0f", h));
  }
  else
  {
    if(w==NULL)  w = 21;
    if(h==NULL)  h = 29.7;
    if(hoff==NULL)  hoff = 0;
    if(voff==NULL)  voff = 0;
    putenv(sprintf("PGPLOT_PS_WIDTH=%.0f", w/0.00254));
    putenv(sprintf("PGPLOT_PS_HEIGHT=%.0f", h/0.00254));
    putenv(sprintf("PGPLOT_PS_HOFFSET=%.0f", hoff/0.00254));
    putenv(sprintf("PGPLOT_PS_VOFFSET=%.0f", voff/0.00254));
  }
}
