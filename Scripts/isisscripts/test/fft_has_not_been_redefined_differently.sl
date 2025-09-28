require("./share/isisscripts.sl");

variable input = [0, 1, 0, 1],  sgn = +1;
variable actual_output = fft(input, sgn);
variable expected_output = [1, 0, -1, 0];  % gsl's fft would give [2, 0, -2, 0]

variable passed = (sumsq(actual_output - expected_output) < 1e-12);
ifnot(passed) vmessage("Error: fft does not behave as ISIS' fft function should. (Maybe it has been redefined by the gsl-module?)\n");
exit(passed ? 0 : 1);
