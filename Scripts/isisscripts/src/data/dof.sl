%%%%%%%%%%%%%%%%
define dof()
%%%%%%%%%%%%%%%%
%!%+
%\function{dof}
%
%\synopsis{Number of degrees of freedom}
%\usage{Double_Type = dof (hist_index);}
%\description
%       Use this function to retrieve number of
%       degrees of freedom.
%\example
%       isis>xray = load_data("data.pha");
%       isis>variable num = dof(1);
%
%\seealso{num_bin}
%!%-
{
  variable dset;
  
  switch(_NARGS)
  { case 1: dset  = (); }
  { help(_function_name()); return; }

  return int(num_bin(dset; dof));
}