%%%%%%%%%%%%%%%%%%%%%
define load_data_combined()
%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{load_data_combined}
%\synopsis{reads and combines the given rows from a Fits Type II pha file}
%\usage{Integer_Type load_data_combined(String_Type, pha_filename, Integer_Type[] rows);}
%\description
%    A combination of load_data and combine_datasets, with
%    the exception that the rows appear as a single dataset.
%
%    All qualifiers are passed to load_data.
%
%\seealso{load_data, combine_datasets}
%!%-
{
  if (_NARGS != 2) { help(_function_name); return; }
  variable phafile, rows;
  (phafile, rows) = ();

  % first, load the data the classical way
  variable did = load_data(phafile, rows;; __qualifiers);
  % get the combined exposure time
  variable exposure = sum(array_map(Double_Type, &get_data_exposure, did)); 
  % combine them and retrieve the combined data structure
  variable gid = combine_datasets(did);
  variable data = _A(get_combined(gid, &get_data_counts));
  uncombine_datasets(gid);
  delete_data(did);
  % define the data
  variable nid = define_counts(data);
  set_data_exposure(nid, exposure);
  variable backfile = fits_read_key(phafile, "BACKFILE");
  if (backfile != "none") {
    if (path_dirname(backfile) == ".") backfile = path_dirname(phafile) + "/" + backfile;
    ()=define_back(nid, backfile);
  }
  variable ancrfile = fits_read_key(phafile, "ANCRFILE");
  if (ancrfile != "none") {
    if (path_dirname(ancrfile) == ".") ancrfile = path_dirname(phafile) + "/" + ancrfile;
    assign_arf(load_arf(ancrfile), nid);
  }
  variable respfile = fits_read_key(phafile, "RESPFILE");
  if (respfile != "none") {
    if (path_dirname(respfile) == ".") respfile = path_dirname(phafile) + "/" + respfile;
    assign_rmf(load_rmf(respfile), nid);
  }
  return nid;
}
