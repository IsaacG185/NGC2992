define renormalizeTo()
{
  variable id, norms;
  switch(_NARGS)
  { case 2: (id, norms) = (); }
  { % else:
      message("usage: renormalizeTo(id, norm);");
      return;
  }
  variable factor = get_par("constant("+string(id)+").factor");
  variable norm;
  foreach norm ([norms])
  { set_par(norm, get_par(norm)*factor); }
  variable data;
  foreach data (all_data)
  { variable par = "constant("+string(data)+").factor";
    if(get_par(par)==1) { thaw(par); }
    set_par(par, get_par(par)/factor);
    if(data==id) { freeze(par); }
  }
}
