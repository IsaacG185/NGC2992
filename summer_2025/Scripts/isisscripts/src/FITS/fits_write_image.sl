define fits_write_image()
%!%+
%\function{fits_write_image}
%\synopsis{writes an image to a FITS file}
%\usage{fits_write_image(FITSfile[, extname], image);
%\altusage{fits_write_image(FITSfile, extname, image, [xvalues, yvalues[, xlabel, ylabel]][, comments]);}
%}
%\qualifiers{
%\qualifier{WCS}{[=\code{""}]: world coordinate system to use, e.g. \code{"P"}}
%}
%\description
%    It is assumed that \code{x}/\code{yvalues} (if provided) are linear arrays,
%    such that \code{CRVAL = values[0]} and \code{CDELT = (values[-1]-values[0])/(length(values)-1)}.
%    \code{x}/\code{ylabel} can be a "label [unit]" string.
%\seealso{fits_write_image_hdu}
%!%-
{
  variable FITSfile, extname="image", image, xvalues=NULL, yvalues=NULL, xlabel="x", ylabel="y", comments=NULL;
  switch(_NARGS)
  { case 2: (FITSfile,          image                                            ) = (); }
  { case 3: (FITSfile, extname, image                                            ) = (); }
  { case 4: (FITSfile, extname, image,                                   comments) = (); }
  { case 5: (FITSfile, extname, image, xvalues, yvalues                          ) = (); }
  { case 6: (FITSfile, extname, image, xvalues, yvalues,                 comments) = (); }
  { case 7: (FITSfile, extname, image, xvalues, yvalues, xlabel, ylabel          ) = (); }
  { case 8: (FITSfile, extname, image, xvalues, yvalues, xlabel, ylabel, comments) = (); }
  { help(_function_name()); return; }

  variable xunit="", yunit="";
  variable m = string_matches(xlabel, `\(.*\) \[\(.*\)\]`, 1);
  if(m!=NULL)  (xlabel, xunit) = (m[1], m[2]);
  m = string_matches(ylabel, `\(.*\) \[\(.*\)\]`, 1);
  if(m!=NULL)  (ylabel, yunit) = (m[1], m[2]);

  fits_write_image_hdu(FITSfile, extname, image, NULL, struct { history=NULL, comment=comments });
  variable axis;
  variable WCS = qualifier("WCS", "");
  if(xvalues!=NULL && yvalues!=NULL)
  {
    foreach axis ([{"1", xlabel, xunit, xvalues}, {"2", ylabel, yunit, yvalues}])
    {
      variable i=axis[0], val = axis[3],  delt = (val[-1]-val[0])/(length(val)-1.);
      % world coordinate system used for, e.g., region files
      fits_update_key(FITSfile, "CTYPE"+i+WCS, axis[1], "i.e., a 'LINEAR' WCS");
      fits_update_key(FITSfile, "CUNIT"+i+WCS, axis[2], "Unit of axis $i"$);
      fits_update_key(FITSfile, "CRPIX"+i+WCS, 1,  "WCS reference pixel of ax.$i"$);
      fits_update_key(FITSfile, "CRVAL"+i+WCS, val[0],  "WCS $i-coord. at ref. pixel"$);
      fits_update_key(FITSfile, "CDELT"+i+WCS, delt,  "WCS pixel size of axis $i"$);
      % physical coordinates shown in ds9
      fits_update_key(FITSfile, "LTV$i"$, 1-val[0]/delt, "IRAF image coordinate Value");
      fits_update_key(FITSfile, "LTM${i}_$i"$, 1/delt, "IRAF image transform Matrix");
    }
    fits_write_comment(FITSfile, "image coordinate[x] = LTM1_1 * x + LTM1_2 * y + LTV1");
    fits_write_comment(FITSfile, "image coordinate[y] = LTM2_1 * x + LTM2_2 * y + LTV2");
  }
}
