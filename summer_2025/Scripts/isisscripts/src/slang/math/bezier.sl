require( "vector" );

define bezNp ()
{
%!%+
%\function{bezNp}
%\synopsis{calulates a Bezier curve between vectors}
%\usage{Vector_Type bez = bezNp(Vector_Type vectors);
%}
%\description
%   The Bezier curve between each pair of the arrays in 'vectors'
%   will be calculated. The 'vectors' arrays needs to be at least two
%   entries.
%   Returned value 'bez' will be one entry shorter than 'vectors'.
%   Main working horse for the bezier function.
%   
%\seealso{bezier}
%!%-

  switch(_NARGS)
    { case 1:
	variable bez = () ;
    }
    { return help(_function_name()); }

  if (length(bez)<2) {message("ERROR (bezNP): vectors array needs to be at least 2 entries"); return ;}
  
  variable wfac = [1:0:#length(bez[0].x)] ;
  variable v ;
  variable bez2 = Vector_Type[length(bez)-1] ;
  _for v (0, length(bez)-2, 1)
    {
      bez2[v] = vector(wfac*bez[v].x + (1-wfac)*bez[v+1].x, wfac*bez[v].y + (1-wfac)*bez[v+1].y, wfac*bez[v].z + (1-wfac)*bez[v+1].z) ;
    }
  return bez2 ;
}
  
define make_conlines ()
{
  variable points, nbins ;
  switch(_NARGS)
    { case 2:
	(points,nbins) = () ;
    }
    { return help(_function_name()); }

  variable p ;
  variable conlines = Vector_Type[length(points)-1] ;

  _for p (0, length(points)-2, 1)
    {
      conlines[p] = vector([points[p][0]:points[p+1][0]:#nbins],
			   [points[p][1]:points[p+1][1]:#nbins],
			   0) ;
    }
  return conlines ;
}

define bezier () {
%!%+
%\function{bezier}
%\synopsis{calulates a Bezier curve from given supporting points}
%\usage{Vector_Type bez = bezier(List_Type points, Integer_Type nbins);
%}
%\description
%   Bezier calculates the Bezier curve between the first and last
%   [x,y] entry of 'points', using the other entries of 'points' as
%   supporting points. 'points' must be a List_Type, with each
%   element containing the [x,y] values of the corresponding point.
%   'nbins' gives the numbers of points used to calculate each part
%   of the curve, as well as the length of the returned curve.
%   
%\qualifiers{
%\qualifier{allbez}{if set, all intermediate Bezier curves are
%          returned as a List, containing all the Vector_Type Bezier curves.}
%\qualifier{conline}{if set, the initial lines connecting the
%          points are also returned, i.e., the return value becomes (Vector_Type
%          conlines, Vector_Type bez).}
%}
%   
%\seealso{xfig_plot_allbezier, bezNp}
%!%-

  variable points, nbins ;
  switch(_NARGS)
    { case 2:
	(points,nbins) = () ;
    }
    { return help(_function_name()); }

  variable conlines = make_conlines( points, nbins) ;
  variable bez = bezNp(conlines) ;
  variable bezarr = {bez} ;

    while (length(bez) > 1)
      {
	bez = bezNp(bez) ;
	if (qualifier_exists("allbez"))
	  { list_append(bezarr,bez) ;}
      }
  if (qualifier_exists("conlines")) {
	if (qualifier_exists("allbez")) {
	  return conlines, bezarr ;
	}
    return conlines, bez[0] ;
  }
  
  else {
    if (qualifier_exists("allbez")) {
      return bezarr ;
    }
   return bez[0] ;
  }
}

define xfig_plot_allbezier () {
%!%+
%\function{xfig_plot_allbezier}
%\synopsis{adds the plot of all Bezier curves from the bezier function to a xfig plot object}
%\usage{Xfig_Struct pl_new = xfig_plot_allbezier(Xfig_struct pl, bez [, conlines ]);
%}
%\description
%   Adds the plot of all Bezier curves to a previously defined
%   xfig-object 'pl'. 'conlines' and 'bez' are the values returned from
%   the bezier-function called with both qualifiers "allbez" and
%   "conlines".
%   Colors of each Bezier line collection is changed automatically.
%   If conlines are plotted, they will be plotted in "gray".
%   
%\seealso{bezier}
%!%-

  variable pl, bez ;

  switch(_NARGS)
    { case 2:
	(pl,bez) = () ;
    }
    { case 3:
	variable conlines ;
	(pl,bez,conlines) = () ;
    }
    { return help(_function_name()); }

  variable b,b1,v ;

  if (__is_initialized(&conlines)) {
  foreach v (conlines)
    {
      pl.plot(v.x, v.y ; color="gray", forward_arrow) ;
    }
  }
  variable i =  1;

  foreach b1 (bez)
    {
      foreach b (b1)
	{
	  pl.plot(b.x, b.y ; color= i, depth = 20-i) ;
	}
      i++;
    }
  return pl ;
}
