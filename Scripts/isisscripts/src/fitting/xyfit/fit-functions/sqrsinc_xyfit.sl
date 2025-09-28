define sqrsinc_xyfit() { %{{{
   variable xref, yref, par;
   switch (_NARGS)
   { case 0: return ["center [center]", "norm [norm]", "width [width]", "offset [offset]", "asymmetry [asymmetry]" ]; }
   { case 3: (xref, yref, par) = (); }
   { return; }
   variable x = @xref - par[0];
   variable xx = x*(1+(1+sign(x))*par[4])/par[2];
   @yref = par[3] + par[1] * sqr( sin(xx)/(xx) );
}
%}}}
