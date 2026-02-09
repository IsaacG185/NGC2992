
define get_component()
%!%+
%\function{get_component}
%\synopsis{to extract the component from the epoch files}
%\usage{get_component([array of position number in the epoch file], [array of epoch fits files]);}
%\qualifiers{
%\qualifier{quadrant}{[=1] Quadrant which is defined as a positive distance ( RA, DEC > 0 == 1 || RA < 0, DEC > 0 == 2 ||
%  RA < 0, DEC < 0 == 3 || RA > 0, DEC < 0 == 4)}
%\qualifier{zero}{shift all distances, so that the last component is at 0,0 ("core" component) }
%}
%\description
%   This function returns a structure of a component.
%   The required input is the position number starting by 1 in each epoch, and a corresponding list of epoch fits files.
%   If a component is not existent in an epoch, the position number of the component must be 0.
%!%-
{
  variable components, ep;
  switch(_NARGS)
  { case 2: (components, ep) = (); }
  { return help(_function_name()); }

  variable q = qualifier("quadrant", 1);
  variable Epoch = qualifier_exists ("zero")
                 ? read_ep(ep; quadrant=q, zero)
                 : read_ep(ep; quadrant=q);

  variable true_comp = where(components);
  variable ntrue_comp = length(true_comp);
  variable comp = struct {
    distance = Double_Type [ntrue_comp],
    flux     = Double_Type [ntrue_comp],
    mjd      = Double_Type [ntrue_comp],
    date     = Double_Type [ntrue_comp],
    tb       = Double_Type [ntrue_comp],
    comp_org = Double_Type [ntrue_comp],
    posangle = Double_Type [ntrue_comp],
    size     = Double_Type [ntrue_comp],
    epochnr  = Int_Type    [ntrue_comp],
    deltax   = Double_Type [ntrue_comp],
    deltay   = Double_Type [ntrue_comp],
    major_ax = Double_Type [ntrue_comp],
    minor_ax = Double_Type [ntrue_comp]
  };

  % to account for the 0 not in the list;
  variable cp = components[true_comp] - 1;
  variable ii;
  _for ii (0, ntrue_comp-1, 1)
  {
    variable jj = true_comp[ii];
    variable kk = cp[ii];
    comp.distance[ii] = Epoch[jj].distance[kk];
    comp.deltax  [ii] = Epoch[jj].deltax[kk];
    comp.deltay  [ii] = Epoch[jj].deltay[kk];
    comp.flux    [ii] = Epoch[jj].flux[kk];
    comp.mjd     [ii] = Epoch[jj].mjd;
    comp.date    [ii] = yearOfMJD(Epoch[jj].mjd);
    comp.tb      [ii] = Epoch[jj].tb[kk];
    comp.comp_org[ii] = components[jj];
    comp.posangle[ii] = Epoch[jj].posangle[kk];
    comp.major_ax[ii] = Epoch[jj].major_ax[kk];
    comp.minor_ax[ii] = Epoch[jj].minor_ax[kk];
    comp.size    [ii] = PI * Epoch[jj].major_ax[kk] * Epoch[jj].minor_ax[kk];
    comp.epochnr [ii] = jj;
  }

  return comp;
}
