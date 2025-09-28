define close_aa1col_xlabel(x_min,x_max,y_min,y_max,x_label)
{
   color(1);
   xylabel((x_max-x_min)/2+x_min, y_min-(y_max-y_min)/7, x_label, 0, 0.5);
   charsize(1);
   _pgscf(1);
   close_plot;
}
