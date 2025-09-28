define get_source_counts()
%!%+
%\function{get_source_counts}
%\synopsis{calculates source counts, background counts and background-subtracted source counts from given spectrum, with errors }
%\usage{Double_Type get_source_counts(Integer_Type id, Integer_Type backid, Double_Type emin, Double_Type emax);}
%\description
%    - spectrum and background have to be already loaded (id, backid)
%    - arf and rmf have to be already loaded and assigned
%\seealso{load_data,assign_rmf,assign_arf}
%!%-
{
  variable id,backid,emin,emax;
  switch(_NARGS)
  { case 4: (id,backid,emin,emax) = (); }
  { help(_function_name()); return; }

    variable cdat,cback,ilo,ihi,q,specArea,backArea,roc_val;

    variable totcts =Double_Type;
    variable speccts=Double_Type;
    variable backcts=Double_Type;
    variable totcts_err =Double_Type;
    variable speccts_err=Double_Type;
    variable backcts_err=Double_Type;
        
    cback   = _A(get_data_counts(backid)); % background data counts
    cdat    = _A(get_data_counts(id));   % spectrum data counts

    ilo     = where( cdat.bin_lo<emin ); % get counts within emin < cts < emax
    ihi     = where( cdat.bin_hi>emax );

    totcts       = sum( cdat.value[[ ilo[length(ilo)-1]:ihi[0] ]] ); % total counts
    totcts_err   = sqrt( sum((cdat.err[[ilo[length(ilo)-1]:ihi[0]]])^2) );
    backcts      = sum( cback.value[[ ilo[length(ilo)-1]:ihi[0]]] ); % background counts
    backcts_err  = sqrt( sum((cback.err[[ ilo[length(ilo)-1]:ihi[0]]])^2) );

    specArea     = get_data_backscale(id); % correct for different region sizes
    backArea     = get_data_backscale(backid);
    speccts      = totcts-(specArea/backArea)*backcts; % back. corr. spec. counts
    speccts_err  = sqrt(backcts_err^2+totcts_err^2);

    return (totcts,totcts_err,speccts,speccts_err,backcts,backcts_err);
}
