define group_pha (id)
%!%+
%\function{group_pha}
%\synopsis{Apply quality and grouping information from pha file}
%\usage{group_pha(indx)}
%\seealso{load_pha}
%!%-
{
  variable file = get_data_info(id).file;

  if (NULL == file)
    throw IsisError, sprintf("Warning: data set %d not found", id);

  variable fp = fits_open_file(file, "r");

  if (NULL == fp || _fits_movnam_hdu(fp, _FITS_BINARY_TBL, "SPECTRUM", 0))
    throw ReadError, sprintf("Failed opening file for reading: %s", file);

  variable qual, grp, colnum;
  
  ifnot (_fits_get_colnum(fp, "QUALITY", &colnum))
    qual = not reverse(fits_read_col(fp, colnum));
  else
    qual = 1;

  ifnot (_fits_get_colnum(fp, "GROUPING", &colnum))
    grp = x2i_group(fits_read_col(fp, colnum));
  else
    grp = 0;

  rebin_data(id, grp*qual);
  fits_close_file(fp);
} 

define load_pha (file)
%!%+
%\function{load_pha}
%\synopsis{Load pha file with grouping and quality information}
%\usage{load_pha("pha_filename")}
%\seealso{group_pha}
%!%-
{
  variable id = load_data(file);

  if (id < 1) return id; % error in load data

  try {
    group_pha(id);
  } catch IsisError, ReadError, sprintf("Failed opening file for reading: %s", file);

  return id;
}
