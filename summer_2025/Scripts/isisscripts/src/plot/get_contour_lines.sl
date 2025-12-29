define get_contour_lines()
%!%+
%\function{get_contour_lines}
%\synopsis{finds a set of contour lines for a 2d-array of values}
%\usage{Struct_Type l[] = get_contour_lines(Double_Type f[], Double_Type f0);}
%\qualifiers{
%\qualifier{save}{filename of a FITS file to save contours}
%}
%\description
%    \code{f} has to be a two-dimensional array (an image).
%    The return value is an array of \code{struct { x, y }},
%    whose fields \code{x} and \code{y} contain the indices
%    for the contour line \code{f[y,x] = f0}.
%!%-
{
  variable f, f0;
  switch(_NARGS)
  { case 2: (f, f0) = (); }
  { help(_function_name()); return; }

  variable save = qualifier("save");
  variable F, n, list, i;
  if(save!=NULL && stat_file(save)!=NULL)
  {
    F = fits_open_file(save, "r");
    ()=_fits_get_num_hdus(F, &n);
    fits_move_to_interesting_hdu(F);
    n--;
    list = Struct_Type[n];
    _for i (0, n-1, 1)
    { list[i] = fits_read_table(F);
      ()=_fits_movrel_hdu(F, +1);
    }
    fits_close_file(F);
    return list;
  }

  variable w = length(f[0,*]);
  variable h = length(f[*,0]);
  variable p = Integer_Type[h, w];
  p[*] = 0;
  n=0;
  variable x, y;
  foreach (where(f>=f0))
  { i = ();
    y = i/w;
    x = i mod w;
    if(   any(f[[int(_max(0, y-1)):int(_min(h-1, y+1))], x]<f0)
       or any(f[y, [int(_max(0, x-1)):int(_min(w-1, x+1))]]<f0))
    { n++; p[y,x] = n; }
    else
    { p[y,x] = -1; }
  }
%  _for $1 (h-1, 0, -1) { print(strjoin(array_map(String_Type, &sprintf, "%3d", p[$1,*]), " ")); }

  i = where(p>0);
  x = i mod w;
  y = i / w;
  list = Struct_Type[0];
  while(length(x)>0)
  { variable X, Y;
    for(X=Integer_Type[0], Y=Integer_Type[0], n=0;  length(x)>0;  )
    { X = [X, x[n]];
      Y = [Y, y[n]];
      x = array_remove(x, n);
      y = array_remove(y, n);
      if(length(x)>0)
      { n = where_min( (x-X[-1])^2 + (y-Y[-1])^2 )[0];
        if( (x[n]-X[-1])^2 + (y[n]-Y[-1])^2 > 2)
          break;
      }
    }
    list = [list, struct {x=X, y=Y}];
  }

  variable j, something_changed;
  do
  { something_changed = 0;
    for(i=0; i<length(list)-1 and not something_changed; i++)
      for(j=i+1; j<length(list) and not something_changed; j++)
      {
	if( (list[i].x[ 0]-list[j].x[ 0])^2 + (list[i].y[ 0]-list[j].y[ 0])^2 <= 2 )
	{ % list[i] = *---|, list[j] = *---|  (* can be connected)
	  list[i].x = [reverse(list[i].x), list[j].x];
	  list[i].y = [reverse(list[i].y), list[j].y];
	  list = array_remove(list, j);
	  something_changed = 1;
	  break;
	}
	if( (list[i].x[ 0]-list[j].x[-1])^2 + (list[i].y[ 0]-list[j].y[-1])^2 <= 2 )
	{ % list[i] = *---|, list[j] = |---*  (* can be connected)
	  list[i].x = [list[j].x, list[i].x];
	  list[i].y = [list[j].y, list[i].y];
	  list = array_remove(list, j);
	  something_changed = 1;
	  break;
	}
	if( (list[i].x[-1]-list[j].x[ 0])^2 + (list[i].y[-1]-list[j].y[ 0])^2 <= 2 )
	{ % list[i] = |---*, list[j] = *---|  (* can be connected)
	  list[i].x = [list[i].x, list[j].x];
	  list[i].y = [list[i].y, list[j].y];
	  list = array_remove(list, j);
	  something_changed = 1;
	  break;
	}
	if( (list[i].x[-1]-list[j].x[-1])^2 + (list[i].y[-1]-list[j].y[-1])^2 <= 2 )
	{ % list[i] = |---*, list[j] = |---*  (* can be connected)
	  list[i].x = [list[i].x, reverse(list[j].x)];
	  list[i].y = [list[i].y, reverse(list[j].y)];
	  list = array_remove(list, j);
          something_changed = 1;
	  break;
	}
      }
  } while(something_changed);

  if(save!=NULL)
  { F = fits_open_file(save, "c");
    _for i (0, length(list)-1, 1)
      fits_write_binary_table(F, string(i), list[i]);
    fits_close_file(F);
  }
  return list;
}
