%%%%%%%%%%%%%%%
define epatplot()
%%%%%%%%%%%%%%%
%!%+
%\function{epatplot}
%\usage{epatplot(Struct_Type events);}
%!%-
{
  variable e;
  switch(_NARGS)
  { case 1: e = (); }
  { help(_function_name()); return; }

  variable po = get_plot_options;

  variable N = 75;
  variable Elo, Ehi; (Elo, Ehi) = log_grid(0.2, 12, N);
  variable inv_dE = 1./(Ehi-Elo);
  variable tot = histogram(e.pi/1e3, Elo, Ehi) * inv_dE;
  tot[where(tot==0)] = 1;
  variable s = where(   e.pattern== 0);  if(length(s)>0)  s = histogram(e.pi[s]/1e3, Elo, Ehi) * inv_dE;  else s = Integer_Type[N];
  variable d = where(1<=e.pattern<= 4);  if(length(d)>0)  d = histogram(e.pi[d]/1e3, Elo, Ehi) * inv_dE;  else d = Integer_Type[N];
  variable t = where(5<=e.pattern<= 8);  if(length(t)>0)  t = histogram(e.pi[t]/1e3, Elo, Ehi) * inv_dE;  else t = Integer_Type[N];
  variable q = where(9<=e.pattern<=12);  if(length(q)>0)  d = histogram(e.pi[q]/1e3, Elo, Ehi) * inv_dE;  else q = Integer_Type[N];

  multiplot([2,1,2]);
  xlabel("Energy [keV]");
  xrange(0.15, 13);
  xlog;

  ylabel("counts / keV");
  $1 = [s, d, t, q];
  yrange(min_max($1[where($1>0)]));
  ylog;
  color(2);  hplot(Elo, Ehi, s);
  color(4); ohplot(Elo, Ehi, d);
  color(3); ohplot(Elo, Ehi, t);
  color(5); ohplot(Elo, Ehi, q);
  color(2); xylabel_in_box(0.95, 0.85, "s", 0, 1);
  color(4); xylabel_in_box(0.95, 0.7 , "d", 0, 1);
  color(3); xylabel_in_box(0.95, 0.55, "t", 0, 1);
  color(5); xylabel_in_box(0.95, 0.4 , "q", 0, 1);

  ylabel("counts / keV");
  $1 = [s, 4*d, 3*t, 4*q];
  yrange(min_max($1[where($1>0)]));
  color(2);  hplot(Elo  , Ehi  ,    s);
  color(4); ohplot(Elo/2, Ehi/2,  4*d);
  color(3); ohplot(Elo/3, Ehi/3,  9*t);
  color(5); ohplot(Elo/4, Ehi/4, 16*q);
  color(2); xylabel_in_box(0.95, 0.85, "1s @ E/1", 0, 1);
  color(4); xylabel_in_box(0.95, 0.65, "2d @ E/2", 0, 1);
  color(3); xylabel_in_box(0.95, 0.45, "3t @ E/3", 0, 1);
  color(5); xylabel_in_box(0.95, 0.25, "4q @ E/4", 0, 1);

  ylabel("fraction");
  ylin;
  yrange(-0.05, 1.05);
  color(6);  hplot(Elo, Ehi, (s+d)/tot);
  color(2); ohplot(Elo, Ehi,  s   /tot);
  color(4); ohplot(Elo, Ehi,    d /tot);
  color(3); ohplot(Elo, Ehi,   t  /tot);
  color(5); ohplot(Elo, Ehi,   q  /tot);
  color(6); xylabel_in_box(0.95, 0.85, "s+d", 0, 1);
  color(2); xylabel_in_box(0.95, 0.7 , "s", 0, 1);
  color(4); xylabel_in_box(0.95, 0.55, "d", 0, 1);
  color(3); xylabel_in_box(0.95, 0.4 , "t", 0, 1);
  color(5); xylabel_in_box(0.95, 0.25, "q", 0, 1);

  set_plot_options(po);
}
