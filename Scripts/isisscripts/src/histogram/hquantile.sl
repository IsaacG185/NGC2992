define hquantile()
{
  variable p, hist;
  switch(_NARGS)
  { case 2: (p, hist) = (); }
  { help(_function_name()); return; }

  variable i, total_sum = sum(hist), partial_sum = 0;
  _for i (0, length(hist)-1, 1)
  { partial_sum += hist[i];
    if(partial_sum >= p*total_sum) { return i; }
  }
  return length(hist)-1;
}
