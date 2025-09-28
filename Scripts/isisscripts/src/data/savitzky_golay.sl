require("gsl", "gsl");

% if the references exist the next block will be evaluated,
% otherwise it won't be loaded (this is the reason why we need "#"-statement here.

% see Numerical Recipes, Third Edition, Section 14.9
% see Savitzky & Golay 1964, Analytical Chemistry, 36, 1627
% see Ziegler 1981, Applied Spectroscopy, 35, 88
% see Bromba & Ziegler 1981, Analytical Chemistry, 53, 1583

define savitzky_golay_coefficients() %{{{
%!%+
%\function{savitzky_golay_coefficients}
%\synopsis{Calculate the Savitzky-Golay coefficients used for data smoothing}
%\usage{Double_Type[] c = savitzky_golay_coefficients(positive Integer_Type nl, nr, p; qualifiers)}
%\description
%    Calculate the Savitzky-Golay coefficients used for data smoothing. The arguments
%    `nl'/`nr' are hereby the data points to the left/right while `p' is the polynomial
%    degree (all have to be positive integer numbers; otherwise their absolute value is
%    rounded to the next nearest integer). The quanity `p' must not exceed `nl'+`nr'!
%    The returned array of coefficients is ordered as [c_-nl, ..., c_0, ..., c_nr].
%\notes
%    Requires GSL module.
%\qualifiers{
%\qualifier{derivative [=0]}{Savitzky-Golay coefficients used for calculating the numerical
%      derivative of the corresponding order (must not exceed `p', i.e., the order of
%      the polynomial).}
%}
%\example
%    % coefficients to smooth data:
%    c = savitzky_golay_coefficients(15,15,4);
%    % -> coefficients to compute first derivative:
%    c = savitzky_golay_coefficients(15,15,4; derivative=1);
%\seealso{savitzky_golay_smoothing}
%!%-
{
  if(_NARGS!=3)
  {
    _pop_n(_NARGS); % remove function arguments from stack
    help(_function_name());
    throw UsageError, sprintf("Usage error in '%s': wrong number of arguments.", _function_name());
  }
  else
  {
    variable nl, nr, p; % nl/nr: number of points to the left/right used for smoothing, p: polynomial degree
    (nl, nr, p) = ();
    nl = nint( abs( nl ) ); % make sure that number of data points to the left is a positive integer
    nr = nint( abs( nr ) ); % make sure that number of data points to the right is a positive integer
    p  = nint( abs( p  ) ); % make sure that degree of polynomial is a positive integer
    variable ld = qualifier("derivative", 0); % which derivative is requested, zero for data fitting
    ld = nint( abs( ld ) ); % make sure that derivative is a positive integer
    if(p>nl+nr)             % p>nl+nr: degree of polynomial is larger than number of data points fitted to
      throw UsageError, sprintf("Usage error in '%s': p must not exceed nl+nr.", _function_name());
    if(ld>p)                % ld>p: desired derivative is larger than degree of polynomial
      throw UsageError, sprintf("Usage error in '%s': The order of the derivative must not exceed p.", _function_name());
    % see Numerical Recipes, Third Edition, Section 14.9 for the following:
    variable matrix = Double_Type[p+1,p+1];
    variable k = [-nl:nr:1];
    variable i,j;
    _for i(0,p,1)
    {
      _for j(0,i,1) % matrix is symmetric
      {
	matrix[i,j] = sum(k^(i+j)); % eq. 14.9.4 in Numerical Recipes, Third Edition
	matrix[j,i] = matrix[i,j];
      }
    }
    variable inverse_matrix = gsl->linalg_LU_invert(gsl->linalg_LU_decomp(matrix));
    variable temp = [0:p:1];
    variable c = Double_Type[nl+nr+1];
    _for i(-nl,nr,1)
    {
      c[i+nl] = sum(inverse_matrix[ld,*]*i^temp); % eq. 14.9.6 in Numerical Recipes, Third Edition
    }
    return prod([2:ld])*c; % prod([2:ld]) = factorial(ld) due to computing the ld-th derivative of a polynomial
  }
}%}}}

define savitzky_golay_smoothing() %{{{
%!%+
%\function{savitzky_golay_smoothing}
%\synopsis{Smooth noisy data by using a Savitzky-Golay filter}
%\usage{Double_Type[] smoothed_data = savitzky_golay_smoothing(Double_Type[] data,
%                                  positive Integer_Type nl, nr, p; qualifiers)}
%\description
%    The idea of Savitzky-Golay filtering is to approximate the given data within
%    a moving window (ranging from `nl' data points to the left to `nr' data points
%    to the right) by a polynomial of order `p'. The respective polynomials are -
%    in principle - determined by least-squares fits to the window data points.
%    Luckily, Savitzky & Golay found a way to replace the fitting and evaluating
%    of the polynomial by taking just linear combinations of neighboring data points
%    tremendously speeding up the smoothing process. However, their method, which
%    is implemented here, is valid only for regularly spaced data points. For more
%    details on the method, see ``Numerical Recipes'', Third Edition, Section 14.9.
%
%    Note that the input parameters `nl', `nr', and `p' have to be positive integer
%    numbers (otherwise their absolute value is automatically rounded to the next
%    nearest integer). The quantity `p' must not exceed the minimum window semi-
%    length min(`nl',`nr') and `nl'+`nr' has to be smaller than or equal to the
%    number of total data points.
%
%    Practical hint: Best results are obtained when the full width of the degree 4
%    Savitzky-Golay filter is between 1 and 2 times the full width at half maximum
%    of the desired features in the data.
%\notes
%    Requires GSL module.
%\qualifiers{
%\qualifier{derivative [=0]}{Apart from smoothing noisy data, the Savitzky-Golay method
%      is also capable to compute numerical derivatives from the fitted polynomials.
%      In order to calculate the `k'-th derivative of the data, set this qualifier
%      equal to `k' and divide the returned array by the data stepsize to the power
%      of `k'. Note that `k' has to be a positive integer (otherwise it is replaced
%      by the next nearest integer of its absolute value). Note that `k' must not
%      exceed `p'.}
%\qualifier{periodic}{Set this qualifer to assume periodic boundary conditions for your
%      data avoiding special treatment of data points close to the edges and thus
%      speeding up the computation. In this case, the condition `p'<min(`nl',`nr')
%      is replaced by `p'<`nl'+`nr'.}
%}
%\example
%    x = [0:20:#1000];
%    data = sin(x);
%    data = data + 0.1*grand(length(x));
%    smoothed_data = savitzky_golay_smoothing(data,100,100,4);
%    first_derivative = savitzky_golay_smoothing(data,100,100,4; derivative=1)/(20./1000.);
%    second_derivative = savitzky_golay_smoothing(data,100,100,4; derivative=2)/(20./1000.)^2;
%\seealso{savitzky_golay_coefficients}
%!%-
{
  if(_NARGS!=4)
  {
    _pop_n(_NARGS); % remove function arguments from stack
    help(_function_name());
    throw UsageError, sprintf("Usage error in '%s': wrong number of arguments.", _function_name());
  }
  else
  {
    variable data, nl, nr, p; % data: data to smooth, nl/nr: number of ponts to the left/right used for smoothing, p: polynomial degree
    (data, nl, nr, p) = ();
    nl = nint( abs( nl ) ); % make sure that number of data points to the left is a positive integer
    nr = nint( abs( nr ) ); % make sure that number of data points to the right is a positive integer
    p  = nint( abs( p  ) ); % make sure that degree of polynomial is a positive integer
    variable ld = qualifier("derivative", 0); % which derivative is requested, zero for data fitting
    ld = nint( abs( ld ) ); % make sure that derivative is a positive integer
    if(p>nl+nr)             % p>nl+nr: degree of polynomial is larger than number of data points fitted to
      throw UsageError, sprintf("Usage error in '%s': p must not exceed nl+nr.", _function_name());
    if(ld>p)                % ld>p: desired derivative is larger than degree of polynomial
      throw UsageError, sprintf("Usage error in '%s': The order of the derivative must not exceed p.", _function_name());
    if(nl+nr>length(data))  % the number of data points used for fitting is larger than the number of available data points
      throw UsageError, sprintf("Usage error in '%s': The number of data points required for fitting is larger than the number of available data points. Reduce nl and/or nr.", _function_name());
    variable coeffs = savitzky_golay_coefficients(nl,nr,p; derivative=ld); % get the Savitzky-Golay-Coefficients
    variable len = length(data);
    % instead of using a for-loop to smooth over neighboring data, create new arrays containing the shifted data
    % then, e.g., shift(data,-1)+shift(data,0)+shift(data,1) is the average over next neighbors
    variable temp = Double_Type[ len, nl+nr+1 ];
    variable i;
    _for i( -nl, nr, 1)
    {
      temp[*,i+nl] = shift(data,i)*coeffs[i+nl];
    }
    variable data_smooth = sum(temp,1);
    % so far: periodic boundary conditions due to use of function 'shift'
    % to have non-periodic boundary condition, the data points at the beginning and end need special treatment:
    if(qualifier_exists("periodic")!=1)
    {
      if(p>nl or p>nr) % p>nl, p>nr: degree of polynomial is larger than the number of data points fitted to at the edges of the data array
	throw UsageError, sprintf("Usage error in '%s': p must not exceed the minimum window semi-length min(nl,nr).", _function_name());
      _for i( 0, nl-1, 1) % data points at the beginning
      {
	variable nr_min = nint(_min(nr,len-i-1));
	coeffs = savitzky_golay_coefficients(i, nr_min, p; derivative=ld);
	data_smooth[i] = sum(data[[0:nr_min+i:1]]*coeffs);
      }
      variable i_temp = i+1;
      _for i( nint(_max(i_temp,len-nr-1)), len-1, 1) % data points at the end
      {
	coeffs = savitzky_golay_coefficients(nl, len-1-i, p; derivative=ld);
	data_smooth[i] = sum(data[[i-nl:len-1:1]]*coeffs);
      }
    }
    return data_smooth;
  }
}%}}}

