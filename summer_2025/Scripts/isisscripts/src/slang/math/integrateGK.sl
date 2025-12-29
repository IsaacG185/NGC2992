% -*- mode: slang; mode: fold -*- %

% Gauss Kronrod G7K15 nodes and weights
private variable GK = 
{
  % Nodes
  [0.000000000000000000000000000000000e+00, 2.077849550078984676006894037732449e-01, 4.058451513773971669066064120769615e-01, 5.860872354676911302941448382587296e-01,
   7.415311855993944398638647732807884e-01, 8.648644233597690727897127886409262e-01, 9.491079123427585245261896840478513e-01, 9.914553711208126392068546975263285e-01],
  % Kronrod weights
  [2.094821410847278280129991748917143e-01, 2.044329400752988924141619992346491e-01, 1.903505780647854099132564024210137e-01, 1.690047266392679028265834265985503e-01,
   1.406532597155259187451895905102379e-01, 1.047900103222501838398763225415180e-01, 6.309209262997855329070066318920429e-02, 2.293532201052922496373200805896959e-02],
  % Gauss weights
  [4.179591836734693877551020408163265e-01, 3.818300505051189449503697754889751e-01, 2.797053914892766679014677714237796e-01, 1.294849661688696932706114326790820e-01]
};

private define integrateGK_one (f, a, b, args, qs)
{
  variable intG, intK, y1, y2,
    m, d, x, y;

  % linear interpolate if difference is small
  if (abs(a-b)/abs(a)<1e-12)
  {
    y1 = @f(a, __push_list(args);; qs);
    y2 = @f(b, __push_list(args);; qs);

    return 0.5*((y2-y1)*(b+a) + (y1*b-y2*a)), 0.0;
  }

  m = 0.5*(a+b);
  d = 0.5*(b-a);
  x = [GK[0][[::2]]*d+m, -GK[0][[2::2]]*d+m];
  y = @f(x, __push_list(args);; qs);

  % Gauss nodes
  intK = sum(y*[GK[1][[::2]], GK[1][[2::2]]]);
  intG = sum(y*[GK[2], GK[2][[1:]]]);

  % Kronrod nodes
  x = [GK[0][[1::2]]*d+m, -GK[0][[1::2]]*d+m];
  y = @f(x, __push_list(args);; qs);
  intK += sum(y*[GK[1][[1::2]],GK[1][[1::2]]]);

  return intK*d, abs(intG-intK)*d;
}

private define integrateGK_recursive (f, a, b, args, qs);
private define integrateGK_recursive (f, a, b, args, qs)
{
  variable tol = qualifier("tolerance", 1e-8);
  variable val, err, val_left, val_right, err_left, err_right;
  (val,err) = integrateGK_one(f, a, b, args, qs);

  if (err/val < tol)
    return val,sqr(err);
  else
  {
    (val_left, err_left) = integrateGK_recursive(f,a,0.5*(b-a),args,qs);
    (val_right, err_right) = integrateGK_recursive(f,0.5*(b-a),b,args,qs);

    return val_left+val_right, err_left+err_right;
  }
}

private define integrateGK_fixed (f, a, b, args, qs)
{
  variable maxIntervals = qualifier("max_intervals", 5);
  variable tol = qualifier("tolerance", 1e-8);

  variable leftBorder = Double_Type[maxIntervals];
  variable rightBorder = Double_Type[maxIntervals];
  variable errorValue = Double_Type[maxIntervals];
  variable integralValue = Double_Type[maxIntervals];
  variable calculated = Char_Type[maxIntervals];
  variable inUseCounter = 0;
  variable numberCalculated = 0;
  variable currentI = 0, newI = 1;
  variable totalIntegral, totalSqError;
  variable left, right, err, val;

  leftBorder[0] = a;
  rightBorder[0] = b;
  inUseCounter++;
  
  while (numberCalculated < inUseCounter)
  {
    ifnot (calculated[currentI])
    {
      (integralValue[currentI], errorValue[currentI]) =
	integrateGK_one(f, leftBorder[currentI], rightBorder[currentI], args, qs);
      calculated[currentI] = 1;
      numberCalculated++;
    }

    if (currentI < newI)
    {
      totalIntegral = sum(integralValue[[currentI:newI-1]]);
      totalSqError = sumsq(errorValue[[currentI:newI-1]]);
    }
    else
    {
      totalIntegral = sum(integralValue[[[currentI:maxIntervals-1],[0:newI-1]]]);
      totalSqError = sumsq(errorValue[[[currentI:maxIntervals-1],[0:newI-1]]]);
    }

    if (abs(sqrt(totalSqError)/totalIntegral)<tol
	|| (abs(totalIntegral)<1e-14 && abs(totalSqError)<DOUBLE_EPSILON))
      return totalIntegral, sqrt(totalSqError);

    left = leftBorder[currentI];
    right = rightBorder[currentI];
    err = errorValue[currentI];
    val = integralValue[currentI];

    if (inUseCounter < maxIntervals)
    {
      if ((abs(val)<tol && abs(err)>tol) || (abs(err/val)>tol))
      {
	% Split interval
	leftBorder[newI] = left;
	rightBorder[newI] = 0.5*(right+left);
	errorValue[newI] = _Inf;
	calculated[newI] = 0;

	newI++;
	if (newI==maxIntervals) newI = 0;

	leftBorder[newI] = 0.5*(right+left);
	rightBorder[newI] = right;
	errorValue[newI] = _Inf;
	calculated[newI] = 0;

	newI++;
	if (newI==maxIntervals) newI = 0;

	calculated[currentI] = 0; % overwrites by chance newI, but thats okay
	inUseCounter++;
	numberCalculated--;
      }
      else
      {
	% Move accepted value one further so we keep the window
	leftBorder[newI] = left;
	rightBorder[newI] = right;
	errorValue[newI] = err;
	integralValue[newI] = val;
	calculated[newI] = 1;
	calculated[currentI] = 0;

	newI++;
	if (newI==maxIntervals)
	  newI = 0;
      }
    }

    currentI++;
    if (currentI == maxIntervals)
      currentI = 0;
  }

  ifnot (qualifier_exists("quiet"))
    vmessage("Integration with %d intervals did not converge (Error: %g)", maxIntervals-1, sqrt(totalSqError));

  return totalIntegral, totalSqError;
}

define integrateGK ()
%!%+
%\function{integrateGK}
%\synopsis{Integrate function with Gauss Kronrod method (G7K15)}
%\usage{Double_Type integrateGK(Ref_Typ fun, Double_Type a, b, ...);}
%\qualifiers{
%  \qualifier{max_intervals}{[=5]: Maximum number of intervals to use}
%  \qualifier{quiet}{: If given, do not message about non-convergence}
%  \qualifier{tolerance}{[=1e-8]: Convergence tolerance}
%  \qualifier{recursive}{If given, integration is done recursively. max_intervals does not apply.}
%  \qualifier{qualifier}{[=NULL]: qualifier structure. Will be passed to function.}
%}
%\description
%  Calculate the integral of a function \code{fun} from \code{a}
%  to \code{b}. It is expected that the first argument of \code{fun}
%  is the integration parameter. Additional arguments can be passed
%  after the integration boundaries. The second return value is the
%  estimated error from the integral value.
%
%\example
%  (val,err) = integrateGK(&sin, 0, PI);
%\seealso{integrateRK4}
%!%-
{
  variable args = __pop_list(_NARGS-3);
  variable qs = qualifier("qualifier");
  variable fun, a, b, val, err;
  (fun, a, b) = ();

  if (qualifier_exists("recursive"))
    (val, err) = integrateGK_recursive(fun, a, b, args, qs;; __qualifiers());
  else
    (val, err) = integrateGK_fixed(fun, a, b, args, qs;; __qualifiers());

  return val, sqrt(err);
}
