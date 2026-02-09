require( "gsl", "gsl" );

%%%%%%%%%%%%%%%%%%%%%%%%%%%
define principal_components()
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{principal_components}
%\synopsis{performs a principal components analysis}
%\usage{Struct_Type PCA = principal_components(Struct_Type s);}
%\description
%    The normalized components (which are stored in \code{PCA.components.c}#i)
%    are calculated from the fields of the structure \code{s}
%    such that they have a mean of 0 and a variance of 1.
%    From them, the covariance matrix \code{PCA.cov_matrix} is calculated,
%    which is diagonalized (see \code{PCA.eigenvalues} and \code{PCA.eigenvectors}).
%    The principal components are stored in \code{PCA.components.pc}#i
%    in ascending order of their contribution to the total variance.
%\qualifiers{
%\qualifier{table}{[="tab"]: name of the structure \code{s}}
%}
%\seealso{cov_matrix}
%!%-
{
  variable s;
  switch(_NARGS)
  { case 1: s = (); }
  { help(_function_name()); return; }

  variable tablename = qualifier("table", "tab");

  variable fieldnames = get_struct_field_names(s);
  variable n_comp = length(fieldnames);
  variable n_data = length(get_struct_field(s, fieldnames[0]));
  variable X = Double_Type[n_data, n_comp];
  variable mom = Struct_Type[n_comp];

  variable PCA = struct { components, cov_matrix, eigenvectors, eigenvalues, frac_variance };
  PCA.components = @Struct_Type(["c" +array_map(String_Type, &string, [1:n_comp]),
                                 "pc"+array_map(String_Type, &string, [1:n_comp])]);
  variable comp;
  _for comp (0, n_comp-1, 1)
  { variable a = get_struct_field(s, fieldnames[comp]);
    mom[comp] = moment(a);
    mom[comp].sdev *= sqrt(mom[comp].num/(mom[comp].num+1.));  % think about that...
    variable c = (a-mom[comp].ave)/mom[comp].sdev;
    set_struct_field(PCA.components, "c"+string(comp+1), c);
    X[*, comp] = c;
  }
  PCA.cov_matrix = cov_matrix(X);
  (PCA.eigenvectors, PCA.eigenvalues) = gsl->eigen_symmv(PCA.cov_matrix);
  PCA.frac_variance = PCA.eigenvalues/sum(PCA.eigenvalues);

  variable i;
  _for i (0, n_comp-1, 1)
  { vmessage("principal component #%d:  [fract. variance: %4.1f%%]", i, 100*PCA.frac_variance[i]);
    variable fmt = "%g*%s.%s";
    variable pc = Double_Type[n_data];
    variable const = 0;
    _for comp (0, n_comp-1, 1)
    { ()=printf(fmt, PCA.eigenvectors[comp,i]/mom[comp].sdev, tablename, fieldnames[comp]);
      pc += PCA.eigenvectors[comp,i] * X[*, comp];
      const -= PCA.eigenvectors[comp,i] * mom[comp].ave/mom[comp].sdev;
      fmt = " %+g*%s.%s";
    }
    vmessage(" %+g\n", const);
    set_struct_field(PCA.components, "pc"+string(i+1), pc);
  }

  return PCA;
}

