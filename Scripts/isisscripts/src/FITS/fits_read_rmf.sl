private define dimi(arr, dim, i, j) {
  switch (dim)
  { case 1: return arr[i][j]; }
  { case 2: return arr[i,j]; }
  { message("error (fits_read_rmf): array has other dimensions than expected"); return; }
}

%%%%%%%%%%%%%%%%%%%%
define fits_read_rmf()
%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{fits_read_rmf}
%\synopsis{retrieves a matrix from a compressed RMF file}
%\usage{Struct_Type rmf = fits_read_rmf(String_Type RMFfile);}
%\description
%     \code{rmf.matrix[j,i]} describes \code{rmf.ebounds.}*\code{[i]} and \code{rmf.energy.}*\code{[j]}.
%\qualifiers{
%\qualifier{check}{checks rmf-normalization: \code{rmf.matrixsum_ebounds} is the sum over all ebounds, which should be 1.}
%\qualifier{spec}{\code{rmf.whitespectrum} is the sum over all ebounds, which should be 1.}
%\qualifier{float}{use for larger RMFs to be able to be loaded in isis.}
%}
%\seealso{fits_plot_rmf}
%!%-
{
  variable RMFfile;
  switch(_NARGS)
  { case 1: RMFfile = (); }
  { help(_function_name()); return; }

  variable fields = ["matrix", "ebounds", "energy"];
  if(qualifier_exists("check"))  fields = [fields, "matrixsum_ebounds"];
  if(qualifier_exists("monospec"))  fields = [fields, "matrixsum_energy"];
  variable result = @Struct_Type(fields);

  variable ebounds = fits_read_table(RMFfile+"[EBOUNDS]");
  variable rmf;
  try { rmf = fits_read_table(RMFfile+"[MATRIX]"); } catch AnyError: { rmf = fits_read_table(RMFfile+"[SPECRESP MATRIX]"); };
  variable n = length(rmf.energ_lo);

  result.matrix = (qualifier_exists("float") ? Float_Type : Double_Type)[n, length(ebounds.channel)];

  result.matrix[*] = 0;
  variable dims = length(array_shape(rmf.n_chan));
  variable dimm = length(array_shape(rmf.matrix));

  variable tlmin = fits_read_key(RMFfile, "TLMIN4");
  if (tlmin == NULL) { % default value
    tlmin = 1;
  }

  variable group_index, iMatrix = 0;
  variable c, i;
  _for c (0, n-1, 1) {
    iMatrix = 0;
    _for group_index (0, length(dims == 1 ? rmf.n_chan[c] : rmf.n_chan[c,*])-1, 1) {
      if (qualifier_exists("verbose")) {
  	vmessage(
	  "channel %d, part %d: first = %d, n = %d\n", c, group_index,
          dimi(rmf.f_chan, dims, c, group_index),
          dimi(rmf.n_chan, dims, c, group_index)
        );
      }
      _for i (0, dimi(rmf.n_chan, dims, c, group_index)-1, 1) {
        result.matrix[c, dimi(rmf.f_chan, dims, c, group_index)+i-tlmin] += dimi(rmf.matrix, dimm, c, iMatrix);
        iMatrix++;
      }
    }
  }
  
  result.ebounds = struct { bin_lo=ebounds.e_min, bin_hi=ebounds.e_max, center=(ebounds.e_min+ebounds.e_max)/2. };
  result.energy = struct { bin_lo=rmf.energ_lo, bin_hi=rmf.energ_hi, center=(rmf.energ_lo+rmf.energ_hi)/2. };

  if (qualifier_exists("check")) {
    n = length(result.matrix[*,0]);
    result.matrixsum_ebounds = Double_Type[n];
    _for i (0, n-1, 1) {
      result.matrixsum_ebounds[i] = sum(result.matrix[i,*]);
    }
  }

  return result;
}
