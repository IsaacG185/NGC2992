variable rmf_absolute_paths = String_Type[0];

%%%%%%%%%%%%%%%%%%
define loadDataset()
%%%%%%%%%%%%%%%%%%
%!%+
%\function{loadDataset}
%\synopsis{loads and assigns one spectrum and its detector response}
%\usage{Integer_Type id = loadDataset(phaFile[, rmfFile[, arfFile[, backFile[, row]]]]);}
%\description
%
%!%-
{
  % process arguments
  %%%%%%%%%%%%%%%%%%%
  variable phaFile=NULL, rmfFile=NULL, arfFile=NULL, backFile=NULL, row=NULL, systematicUncert=0;
  switch(_NARGS)
  { case 1:  phaFile = (); }
  { case 2: (phaFile, rmfFile) = (); }
  { case 3: (phaFile, rmfFile, arfFile) = (); }
  { case 4: (phaFile, rmfFile, arfFile, backFile) = (); }
  { case 5: (phaFile, rmfFile, arfFile, backFile, row) = (); }
  { case 6: (phaFile, rmfFile, arfFile, backFile, row, systematicUncert) = (); }
  { help(_function_name()); return; }

  % load data
  %%%%%%%%%%%
  variable spec;
  if(row!=NULL) { spec = load_data(phaFile, row); } else  { spec = load_data(phaFile); }
  % save infos
  variable info = get_data_info(spec);
  variable exposure = get_data_exposure(spec);

  if(fits_key_exists(phaFile, "BACKFILE"))
  {
    variable FITS_backFile = fits_read_key(phaFile, "BACKFILE");
    if(FITS_backFile != ""  and  FITS_backFile != "none")
    {
      if(backFile!=NULL)
      { message("warning (loadDataset): background loaded via FITS-header keyword; argument of loadDataset ignored"); }
      backFile = FITS_backFile;
    }
  }

  if(backFile != NULL)
  { % load background
    if(fits_key_exists(phaFile, "BACKSCAL") and fits_key_exists(phaFile, "BACKSCUP") and fits_key_exists(phaFile, "BACKSCDN"))
    { % define_back cannot be used for type 2 PHA files
      variable back;
      if(row!=NULL) { back = load_data(backFile, row); } else { back = load_data(backFile); }
      variable s = get_data_counts(spec);
      variable b = get_data_counts(back);
      variable bp = fits_read_key(phaFile, "BACKSCAL"); % background scale
      variable bbu= fits_read_key(phaFile, "BACKSCUP");
      variable bbd= fits_read_key(phaFile, "BACKSCDN");
      variable scale = bp/(bbu+bbd);
      s.value -= b.value*scale;
      variable err = sqrt(s.value + scale*scale*b.value);
      delete_data(spec);
      delete_data(back);
      spec = define_counts(s.bin_lo, s.bin_hi, s.value, err);
      set_data_info(spec, info);
      set_data_exposure(spec, exposure);
    }
    else
    { ()=define_back(spec, backFile);
    }
  }
  set_rebin_error_hook(spec, "rebin_error_hook");

  % load response: ARF & RMF = RSP
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  variable arf=NULL, rmf=NULL;

%  print(info);

  if(info.rmfs[0]>0)
  { if(rmfFile!=NULL)
    { message("warning (loadDataset): RMF already loaded via FITS-header keywords; argument of loadDataset ignored");
      rmfFile = NULL;
    }
    rmf = info.rmfs[0];
    unassign_rmf(rmf);  % will be assigned at the end
  }
  if(info.arfs[0]>0)
  { if(arfFile != NULL)
    { message("warning (loadDataset): ARF already loaded via FITS-header keywords; argument of loadDataset ignored");
      arfFile = NULL;
    }
    arf = info.arfs[0];
    unassign_arf(arf);  % will be assigned at the end
  }

  % loadRMF
  %%%%%%%%%
  if(rmfFile != NULL)
  { rmf = load_rmf(rmfFile); }

  % use absolute paths
  variable rmf_info = get_rmf_info(rmf);
  if(rmf_info.arg_string[0] != '/')
  { rmf_info.arg_string = getcwd() + rmf_info.arg_string;
    set_rmf_info(rmf, rmf_info); % does not (yet at ISIS 1.4.9-13) update arg_string due to src/rmf.c:Rmf_set_info
  }
  rmf_absolute_paths = [rmf_absolute_paths, rmf_info.arg_string];


  % load ARF
  %%%%%%%%%%

  % 1. ARF file
  if(arfFile!=NULL) { arf = load_arf(arfFile); }

  % use absolute paths
  if(arf!=NULL)
  {
    variable arf_info = get_arf_info(arf);
    if(arf_info.file[0] != '/')
    { arf_info.file = getcwd() + arf_info.file;
      set_arf_info(arf, arf_info);
    }
  }

%
%  % 2. XMM/RGS areascal
%  if(fits_key_exists(phaFile, "TELESCOP") and fits_key_exists(phaFile, "INSTRUME"))
%  { if(    substr(fits_read_key(phaFile, "TELESCOP"), 1, 3)=="XMM"
%       and substr(fits_read_key(phaFile, "INSTRUME"), 1, 3)=="RGS")
%    {
%      variable  arfGrid = get_rmf_arf_grid(rmf);
%      variable dataGrid = get_rmf_data_grid(rmf);
%      arfData = struct_combine(arfGrid, "value", "err");
%      variable fracexpo = rebinDensity(arfGrid.bin_lo, arfGrid.bin_hi,
%                                       dataGrid.bin_lo, dataGrid.bin_hi, fits_read_table(phaFile).areascal);
%      arfData.value = fracexpo;
%      arfData.err = 0*fracexpo;
%
%     if(arf==NULL)
%      { arf = define_arf(arfData); }
%      else
%      { arfData.value *= get_arf(arf).value;
%        put_arf(arf, arfData);
%      }
%
%      variable arf_info = get_arf_info(arf);
%      arf_info.fracexpo *= fracexpo;
%      if(arf_info.file==NULL) { arf_info.file = ""; }
%      set_arf_info(arf, arf_info);
%    }
%  }

  % 3. RSP-factors
  if(rmf!=NULL)
  {
    (arf, rmf) = factorized_arf_rmf(arf, rmf);
  }

  % assign response
  %%%%%%%%%%%%%%%%%
  if(rmf!=NULL) { assign_rmf(rmf, spec); }

  if(arf!=NULL)
  { assign_arf(arf, spec);
    if(get_arf_exposure(arf)<0) { set_arf_exposure(arf, get_data_exposure(spec)); }
  }

  % useful commands
  ignore_bad(spec);
  flux_corr(spec);
%  if(fits_key_exists(phaFile, "RFLORDER"))
%  { info = get_data_info(spec);
%    info.order = fits_read_key(phaFile, "RFLORDER");
%    set_data_info(spec, info);
%  }

  return spec;
}
