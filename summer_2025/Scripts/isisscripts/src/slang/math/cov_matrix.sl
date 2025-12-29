define cov_matrix()
%!%+
%\function{cov_matrix}
%\synopsis{computes a covariance matrix}
%\usage{COV = cov_matrix(Struct_Type s);
%\altusage{COV = cov_matrix(Double_Type X[][]);}
%\altusage{COV = cov_matrix(Double_Type x0[], x1[], ...);}
%}
%\description
%    \code{COV[i,j] =} cov(x_i, x_j) = < (x_i - <x_i>) * (x_j - <x_j>) >
%!%-
{
  variable X;
  variable i, j, j1, j2, n, p, mu, cov;
  switch(_NARGS)
  { case 0: help(_function_name()); return; }
  { case 1: X = ();
    if(typeof(X) == Struct_Type)
    { variable tab = X;
      variable fieldnames = get_struct_field_names(tab);
      variable n_comp = length(fieldnames);
      variable n_data = length(get_struct_field(tab, fieldnames[0]));
      X = Double_Type[n_data, n_comp];
      variable mom = Struct_Type[n_comp];
      variable comp;
      _for comp (0, n_comp-1, 1)
        X[*, comp] = get_struct_field(tab, fieldnames[comp]);
    }
  }
  { % else:
    variable x0 = ();
    X = Double_Type[length(x0), _NARGS];
    X[*, _NARGS-1] = x0;
    _for i (_NARGS-2, 0, -1)
      X[*, i] = ();
  }

  variable dims = array_shape(X);

  if(length(dims)==2)  % X[i,j] = jth component of ith vector
  {
    n = dims[0];  % = length(X[*,0]);
    p = dims[1];

    mu = Double_Type[p];
    _for i (0, n-1, 1)
      _for j (0, p-1, 1)
        mu[j] += X[i,j]/n;

    cov = Double_Type[p,p];
    _for i (0, n-1, 1)
      _for j1 (0, p-1, 1)
        _for j2 (0, p-1, 1)
	  cov[j1, j2] += (X[i,j1]-mu[j1])*(X[i,j2]-mu[j2])/n;
    return cov;
  }
  vmessage("error (%s): %d-dimensional arrays are not supported", _function_name(), length(dims));
}
