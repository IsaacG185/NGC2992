% require("isisscripts");
require("../share/isisscripts.sl");

variable tmpfile = "get_confmap";

define degenerate_linear_fit(lo, hi, par)
{
  return par[0]*(par[1]*.5*(lo+hi) + par[2]) + par[3];  % a*(m*x+t) + b
}
add_slang_function("degenerate_linear", ["a", "m", "t", "b"]);

variable lo = [1:10];
()=define_counts(lo-.5, lo+.5, lo, lo*0+1);  % y = 1*x + 0;

fit_fun("degenerate_linear(1)");
set_par("degenerate_linear(1).a", 1);
set_par("degenerate_linear(1).m", 1);
set_par("degenerate_linear(1).t", 0);
set_par("degenerate_linear(1).b", 0);

()=get_confmap(2, .5, 1.5, 5,  % foreach m ([.5, .75, 1, 1.25, 1.5])
	       3, -1, 1, 3     % foreach t ([-1, 0, 1])
	       ; save=tmpfile);
tmpfile += ".fits";
 variable a = fits_read_img(tmpfile+"[2]");
%variable b = fits_read_img(tmpfile+"[3]");
()=remove(tmpfile);

variable a_expected = _reshape([ [2, 4./3, 1, .8, 2./3], dup, dup ], [3,5]);   % a = 1/m
variable diff = a - a_expected;
message("difference <computed> - <expected>");
print(diff);
diff = maxabs(diff);
vmessage("maximum |difference| = %S", diff);

if(diff>1e-7)
  message("test failed"), exit(1);
else
  message("test passed"), exit(0);
