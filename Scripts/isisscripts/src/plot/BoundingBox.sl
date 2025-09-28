define BoundingBox()
%!%+
%\function{BoundingBox}
%\synopsis{retrieves the Bounding Box of a postscript file}
%\usage{Double_Type (x1, y1, x2, y2) = BoundingBox(String_Type psfile);
%\altusage{Double_Type (w, h) = BoundingBox(String_Type psfile; size);}
%}
%\description
%    \code{x1, y1, x2, y2} are the values from the last line in \code{psfile}
%    of the form \code{"%%BoundingBox: x1 y1 x2 y2"}.
%    \code{x1, y1, x2, y2} are \code{NULL} if no such line is found.
%\qualifiers{
%\qualifier{first}{Take the first matching %%BoundingBox line instead of the last.}
%\qualifier{size}{If this qualifier is set, \code{w = x2-x1} and \code{h = y2-y1} are returned.}
%}
%!%-
{
  variable psfile;
  switch(_NARGS)
  { case 1: psfile = (); }
  { help(_function_name()); return; }

  variable x1=NULL, y1=NULL, x2=NULL, y2=NULL;
  variable take_first = qualifier_exists("first");
  variable F = fopen(psfile, "r");
  while(not feof(F))
  {
    variable line = fgetslines(F, 1);
    if(line!=NULL && length(line)>0 && sscanf(line[0], "%%%%BoundingBox: %f %f %f %f", &$1, &$2, &$3, &$4)==4)
    {
      (x1, y1, x2, y2) = ($1, $2, $3, $4);
      if(take_first)  break;
    }
  }
  ()=fclose(F);
  if(qualifier_exists("size"))
    return (x2-x1, y2-y1);
  else
    return (x1, y1, x2, y2);
}
