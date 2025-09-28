% 
% Implementation of 3x3 matrices and some vector routines

require( "vector" );

%%%%%%%%%%%%%%%%%%%%%%%%
define vector_astro ()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{vector_astro}
%\synopsis{vector initializer that is more appropriate for astronomy}
%\usage{Vector_Type vector_astro(Double_Type x, y, z)}
%\altusage{Vector_Type vector_astro(Double_Type r, phi, theta; sph)}
%\altusage{Vector_Type vector_astro(Double_Type r, lon, lat; astro)}
%\altusage{Vector_Type vector_astro(Double_Type phi, theta; sph)}
%\altusage{Vector_Type vector_astro(Double_Type lon, lat; astro)}
%\qualifiers{
%\qualifier{astro}{consider the given coordinates to be astronomical (r, lon, lat)
%                    following the astronomical definition (i.e., lon ranges from
%                    0 to 2pi, lat from -pi/2 to pi/2; default for two arguments)}
%\qualifier{sph}{consider the given coordinates to be spherical (r, phi, theta)
%                  following the mathematical definition (i.e., theta ranges from
%                  0 to pi)}
%\qualifier{deg}{interpret angular arguments in degrees}
%}
%\description
%  The components of the vector are returned within the Vector_Type
%  and are accessible like a structure with the fields x, y, and z. 
%
%  If the astro qualifier is given, cartesian coordinates are
%  calculated as
%#v+
%    [x, y, z] =
%        r * [cos(lon)*cos(lat), sin(lon)*cos(lat), sin(lat)]
%#v-
%  If the sph qualifier is given, the cartesian coordinates are
%  calculated as
%#v+
%    [x, y, z] =
%        r * [cos(phi)*sin(theta), sin(phi)*sin(theta), cos(theta)]
%#v-
%
% If the function is called with only two arguments, then these represent the
% spherical or astronomical coordinates, and we assume that r=1.
%
% If the initializer is called with a single argument of type Vector_Type,
% the corresponding Vector_Type is returned
%
%\seealso{Vector_Type,Matrix33_Type,vector_to_spherical,dms2deg,hms2deg}
%!%-
{
    variable x,y,z;
    switch(_NARGS)
    {case 1: x=();}
    {case 2: (x,y)=();}
    {case 3: (x,y,z) = ();}
    {return help(_function_name());}

    if (Vector_Type == typeof(x)) {
	return vector(x.x,x.y,x.z);
    }
    
    if (__is_numeric (x) != 2) {
	x = typecast (x, Double_Type);
    }
    if (__is_numeric (y) != 2) {
	y = typecast (y, Double_Type);
    }

    if (_NARGS==3) {
	if (__is_numeric (z) != 2) {
	    z = typecast (z, Double_Type);
	}
    }
    
    % spherical coordinates given?
    variable sinphi, cosphi, sintheta, costheta;
    if (_NARGS==2 or qualifier_exists("sph") or qualifier_exists("astro")) {
	if (_NARGS==2) {
	    % no radius given
	    z=y; y=x; x=1.;
	}
	if (qualifier_exists("deg")) {
	    (sinphi, cosphi) = sincos(y*PI/180.);
	    (sintheta, costheta) = sincos(z*PI/180.);
	} else {
	    (sinphi, cosphi) = sincos(y);
	    (sintheta, costheta) = sincos(z);
	}
	if (qualifier_exists("sph")) {
	    return vector(x * cosphi * sintheta, x * sinphi * sintheta, x * costheta);
	};
        % phi: alpha, theta: delta
	return vector(x * cosphi * costheta, x * sinphi * costheta, x * sintheta);
    }
    
    return vector(x,y,z);
}

%%%%%%%%%%%%%%%%%%%%%%%%
define vector_to_spherical ()
%%%%%%%%%%%%%%%%%%%%%%%%
%!%+
%\function{vector_to_spherical}
%\synopsis{Returns the spherical coordinates corresponding to a 3D Vector}
%\usage{(r,lon,lat)=vector_to_spherical(Vector_Type v)}
%\qualifiers{
%\qualifier{astro}{return coordinates using the astronomical convention (the default)}
%\qualifier{sph}{return coordinates (r,theta,phi) using the mathematical definition
%                  (i.e., theta ranges from 0 to pi)}
%\qualifier{deg}{return angular arguments in degrees (default: radian)}
%}
%
%\description
%   This function returns the spherical coordinates corresponding to a vector.
%   See the description of function vector_astro for the relevant equations.
%   
%
%\seealso{Vector_Type,vector_astro,dms2deg,hms2deg}
%!%-
{
    variable v;
    switch(_NARGS) {
	case 1: v=();
    }
    { return help(_function_name());}

    variable r,lon,lat;
    r=hypot(v.x,v.y,v.z);
    
    if (qualifier_exists("sph")) {
	lat=acos(v.z/r);
    } else {
	lat=asin(v.z/r);
    }
    
    lon=atan2(v.y,v.x);
    if (lon<0.) {
	lon+=2.*PI;
    }
    if (qualifier_exists("deg")) {
	lon*=180./PI;
	lat*=180./PI;
    }

    return (r,lon,lat);
}

private define vector_div_scalar () {
    %
    % divide a vector by a scalar
    %
    variable v,a;
    (v,a)=();
    return vector(v.x/a,v.y/a,v.z/a);
}

%!%+
%\datatype{Matrix33_Type}
%\synopsis{3x3 matrix type}
%\description
%  3x3 Matrix type that is compatible with Vector_Type
%
%  The following operations are defined for the Matrix33_Type:
%    * M1+M2: Addition and subtraction of matrices
%    * -M1: Changing sign of a matrix
%    * M1*M2: Matrix - Matrix multiplication
%    * M1*V: Matrix - Vector multiplication (V is a Vector_Type)
%    * M1*f and f*M1: Matrix - real multiplication
%    * M1/M2: Multiply M1 with the inverse of M2. Do NOT use this...
%
%  Objects of type Matrix33_Type can be instantiated with the 
%  following functions (see there for detailed descriptions):
%    * matrix33_new: general initialization
%    * matrix33_diag: return a diagonal matrix
%    * matrix33_scalar: return a scalar matrix
%    * matrix33_null: return a null matrix
%    * matrix33_identity: return an identity matrix
%    * matrix33_rot: return a rotation matrix for the x-, y-, or z-axis
%    * matrix33_reflect: return a reflection matrix for the x-, y-, or z-axis
%
%  Other functions operating on matrices (functions marked with + are also 
%      available through accessor functions):
%    * matrix33_determinant: calculate the determinant of the matrix (+)
%    * matrix33_get_diag: return the diagonal elements of the matrix (+)
%    * matrix33_get_trace: return the sum of the diagonal elements (+)
%    * matrix33_transpose: return the transpose of the matrix (+)
%    * matrix33_adjoint: return the adjoint of the matrix
%    * matrix33_cofactors: return the matrix of cofactors
%
%  The Matrix33_Type object has the following accessors:
%    * m.determinant(): return the determinant of the matrix
%    * m.as_array(): return the elements of the matrix as a 3x3 array
%    * m.transpose(): return the transpose of the matrix (not in place!)
%    * m.diag(): return the diagonal elements as a vector
%    * m.trace(): return the trace of the matrix
%    * m.inverse(): return the inverse of the matrix (not in place!)
%
%!%-
if (0 == is_defined("Matrix33_Type")) {
    typedef struct { m,
            determinant, diag, as_array, transpose, trace, inverse } Matrix33_Type;
}

define matrix33_new();

define matrix33_diag()
%!%+
%\function{matrix33_diag}
%\synopsis{return a diagonal-matrix}
%\usage{ Matrix33_Type=matrix33_diag(m11,m22,m33);}
%\description
%  Returns a 3x3 diagonal matrix. If m11,m22,m33 are given,
%  then the three diagonal values are initialized to these
%  three values. If only m11 is given, then a scalar
%  matrix where all three elements are equal to m11 is
%  returned.
%
%\seealso{Vector_Type, Matrix33_Type}
%!%-
{
    variable m11,m22,m33;
    switch(_NARGS) {
	case 1: m11=();
	m11=double(m11);
	m22=m11;
	m33=m11;
    }
    {
	case 3: (m11,m22,m33)=();
	m11=double(m11);
	m22=double(m22);
	m33=double(m33);
    }
    {
	help(_function_name());
	return;
    }
    return matrix33_new(m11,0.,0.,0.,m22,0.,0.,0.,m33);
}

define matrix33_scalar(val)
%!%+
%\function{matrix33_scalar}
%\synopsis{return a scalar-matrix}
%\usage{ Matrix33_Type=matrix33_scala(m11);}
%\description
%  Returns a 3x3 scalar matrix (a matrix where all diagonal elements have the
%  same value and where all other elements are zero)
%
%\seealso{Vector_Type, Matrix33_Type}
%!%-
{
    return matrix33_diag(double(val));
}

define matrix33_null() 
%!%+
%\function{matrix33_null}
%\synopsis{return a null-matrix}
%\usage{ Matrix33_Type=matrix33_null();}
%\description
%  Returns a 3x3 null-matrix
%
%\seealso{Matrix33_Type}
%!%-
{ 
   return matrix33_diag(0.);
}

define matrix33_identity()
%!%+
%\function{matrix33_identity}
%\synopsis{return a identity-matrix}
%\usage{ Matrix33_Type=matrix33_identity();}
%\description
%  Returns a 3x3 identity matrix.
%
%\seealso{Matrix33_Type}
%!%-
{
    return matrix33_diag(1.);
}


private define matrix33_mat_add_mat(m1,m2) {
    %
    % add two 3x3 matrices
    %
    variable m=matrix33_new();

    m.m=m1.m+m2.m;

    return m;
}

private define matrix33_mat_sub_mat(m1,m2) {
    %
    % subtract a 3x3 matrix from another
    %
    variable m=matrix33_new();

    m.m=m1.m-m2.m;

    return m;
}

private define matrix33_chs(m1) {
    %
    % change the sign of all elements of a 3x3 matrix
    %
    variable m=matrix33_new();

    m.m=-m1.m;

    return m;
}

private define matrix33_mat_mul_mat(m1,m2) {
    %
    % multiply two 3x3 matrices with each other
    %
    variable m=matrix33_new();
    m.m=m1.m # m2.m;
    return m ;
}

private define matrix33_mat_mul_real(m1,fac) {
    %
    % multiply a 3x3 matrix with a number
    %
    variable m=matrix33_new();
    m.m=m1.m*double(fac);
    return m;
}

private define matrix33_real_mul_mat(fac,m1) {
    %
    % multiply a 3x3 matrix with a number
    %
    variable m=matrix33_new();
    m.m=m1.m*double(fac);
    return m;
}

private define matrix33_mat_mul_vector(m1,v) {
    %
    % multiply a 3x3 matrix with a Vector
    %
    return vector(
      m1.m[0,0]*v.x+m1.m[0,1]*v.y+m1.m[0,2]*v.z,
      m1.m[1,0]*v.x+m1.m[1,1]*v.y+m1.m[1,2]*v.z,
      m1.m[2,0]*v.x+m1.m[2,1]*v.y+m1.m[2,2]*v.z
    );
}

private define matrix33_real_mul_mat(fac,m1) {
    %
    % multiply a number with a 3x3 matrix
    %
    return matrix33_mat_mul_real(m1,fac);
}


private define matrix33_mat_div_real(m1,fac) {
    %
    % divide a 3x3 matrix by a number
    %
    variable m=matrix33_new();

    m.m=m1.m/double(fac);

    return m;
}

private define matrix33_real_div_mat(fac,m1) {
    %
    % divide a 3x3 matrix by a number
    %
    return fac*m1.inverse();
}

private define matrix33_mat_div_mat(m1,m2) {
    %
    % multiply a matrix with the inverse of the other matrix
    %
    return matrix33_mat_mul_mat(m1,m2.inverse());
}



private define matrix33_as_string(m1) {
    return sprintf("[[%12g %12g %12g],\n [%12g %12g %12g],\n [%12g %12g %12g]]\n",
                                  m1.m[0,0],m1.m[0,1],m1.m[0,2],
                                  m1.m[1,0],m1.m[1,1],m1.m[1,2],
                                  m1.m[2,0],m1.m[2,1],m1.m[2,2]
    );
}


define matrix33_determinant() 
%!%+
%\function{matrix33_determinant}
%\synopsis{return the determinant of a 3x3 matrix}
%\usage{ det=matrix33_determinant(m);}
%\description
%  Calculates the determinant of a 3x3 matrix. 
%
%\seealso{vector, Vector_Type, Matrix33_Type}
%!%-
{
    variable m;
    switch(_NARGS) {
	case 1: m=();
    }
    {
	help(_function_name());
	return;
    }
    
    return m.m[0,0]*(m.m[1,1]*m.m[2,2]-m.m[1,2]*m.m[2,1])
          -m.m[0,1]*(m.m[1,0]*m.m[2,2]-m.m[1,2]*m.m[2,0])
          +m.m[0,2]*(m.m[1,0]*m.m[2,1]-m.m[1,1]*m.m[2,0]);
}

define matrix33_transpose() 
%!%+
%\function{matrix33_transpose}
%\synopsis{return the transpose of a 3x3 matrix}
%\usage{ Matrix33_Type=matrix33_transpose(m);}
%\description
%  Returns the transpose of a 3x3 matrix
%
%\seealso{vector, Vector_Type, matrix33_new}
%!%-
{
    variable m;
    switch(_NARGS) {
	case 1: m=();
    }
    {
	help(_function_name());
	return;
    }

    return matrix33_new(m.m[0,0],m.m[1,0],m.m[2,0],
                        m.m[0,1],m.m[1,1],m.m[2,1],
                        m.m[0,2],m.m[1,2],m.m[2,2]);
}

define matrix33_cofactors()
{
    variable m=();
    return matrix33_new(
      +(m.m[1,1]*m.m[2,2]-m.m[2,1]*m.m[1,2]),
      -(m.m[1,0]*m.m[2,2]-m.m[2,0]*m.m[1,2]),
      +(m.m[1,0]*m.m[2,1]-m.m[2,0]*m.m[1,1]),
      -(m.m[0,1]*m.m[2,2]-m.m[2,1]*m.m[0,2]),
      +(m.m[0,0]*m.m[2,2]-m.m[2,0]*m.m[0,2]),
      -(m.m[0,0]*m.m[2,1]-m.m[2,0]*m.m[0,1]),
      +(m.m[0,1]*m.m[1,2]-m.m[1,1]*m.m[0,2]),
      -(m.m[0,0]*m.m[1,2]-m.m[1,0]*m.m[0,2]),
      +(m.m[0,0]*m.m[1,1]-m.m[1,0]*m.m[0,1]));
}

define matrix33_adjoint()
{
    variable m=();
    return matrix33_cofactors(m).transpose();
}

define matrix33_inverse()
{
    variable m=();
    return matrix33_adjoint(m)* 1./m.determinant();
}


define matrix33_as_array() 
%!%+
%\function{matrix33_as_array}
%\synopsis{return the contents of the matrix as a 3x3 matrix}
%\usage{ arr=matrix33_as_array(m);}
%\description
%  Return the contents of the matrix as a 3x3 array
%
%\seealso{vector, Vector_Type, matrix33_new}
%!%-
{
    variable m;
    switch(_NARGS) {
	case 1: m=();
    }
    {
	help(_function_name());
	return;
    }
    return m.m[*,*];
}

define matrix33_get_diag() 
%!%+
%\function{Vector_Type=matrix33_get_diag(Matrix33_Type)}
%\synopsis{return the diagonal elements of a 3x3 matrix}
%\usage{ dia=matrix33_get_diag(m);}
%\description
%  Return the diagonal elements of a Matrix33_Type as a Vector_Type.
%  Also available through the accessor function m.diag
%
%\seealso{vector,Vector_Type, matrix33_new}
%!%-
{
    variable m;
    switch(_NARGS) {
	case 1: m=();
    }
    {
	help(_function_name());
	return;
    }
    
    return vector(m.m[0,0],m.m[1,1],m.m[2,2]);
}

define matrix33_get_trace() 
%!%+
%\function{Vector_Type=matrix33_get_trace(Matrix33_Type)}
%\synopsis{return the trace of a 3x3 matrix}
%\usage{trac=matrix33_get_trace(m);}
%\description
%  Return the sum of the diagonal elements of a Matrix33_Type
%  Also available through the accessor function m.trace
%
%\seealso{vector,Vector_Type, matrix33_new}
%!%-
{
    variable m;
    switch(_NARGS) {
	case 1: m=();
    }
    {
	help(_function_name());
	return;
    }
    
    return m.m[0,0]+m.m[1,1]+m.m[2,2];
}


define matrix33_new()
%!%+
%\function{matrix33_new}
%\synopsis{instantiate a 3x3 matrix}
%\usage{ Matrix33_Type=matrix33_new();}
%\description
% Instantiates a new 3x3 matrix object.
%  The following initializers are available:
%    * No arguments: a zero-Matrix is returned
%    * One argument:
%        If the argument is of type Matrix33_Type: a copy of the argument
%           is returned
%        If the argument is a scalar: all matrix elements are initialized to
%           this scalar (use matrix33_diag to initialize a diagonal matrix!)
%        If the argument is an array with 9 elements: the matrix is initialized
%           to these elements
%    * Nine arguments: matrix elements m11,m12,m13,m21,m22,m23,m31,m32,m33,
%      i.e., the elements are in row order and the matrix is:
%
%               m11 m12 m13
%          M =  m21 m22 m23
%               m31 m32 m33
%
%\seealso{Matrix33_Type, Vector_Type}
%!%-
{
    variable m=@Matrix33_Type;
    m.m=Double_Type[3,3];
    
    variable mat;
    switch(_NARGS)
    {
	case 0:
	m.m[*,*]=0.;
    }
    {
	case 1:
	mat=();
	if (Matrix33_Type==typeof(mat)) {
	    m.m[*,*]=mat.m[*,*];
	} else {
	    if (Array_Type==typeof(mat)) {
		if ((array_shape(mat))[0]==9) {
		    m.m[*,*]=double(mat);
		} else {
		    throw UsageError,sprintf("%s: array argument must have 9 elements\n",_function_name());
		}
	    } else {
		if (Double_Type==typeof(mat)) {
		    m.m[*,*]=mat;
		} else {
		    throw UsageError,sprintf("%s: single argument must be of Matrix33_Type or an array\n",_function_name());
		}
	    }
	}
    }
    {
	case 9:
	variable m11,m12,m13,m21,m22,m23,m31,m32,m33;
	(m11,m12,m13,m21,m22,m23,m31,m32,m33)=();
	m.m[*,*]=[[double(m11),double(m12),double(m13)],
                  [double(m21),double(m22),double(m23)],
                  [double(m31),double(m32),double(m33)]];

    }

    m.determinant=&matrix33_determinant;
    m.diag=&matrix33_get_diag;
    m.as_array=&matrix33_as_array;
    m.transpose=&matrix33_transpose;
    m.trace=&matrix33_get_trace;
    m.inverse=&matrix33_inverse;
    return m;    
}


%%%%%%%%%%%%%%%%%
define matrix33_reflect()
%%%%%%%%%%%%%%%%%
%!%+
%\function{matrix33_reflect}
%\synopsis{return a 3x3 reflection matrix to change the handedness of the ith axis}
%\usage{ Matrix33_Type=matrix33_reflect(i);}
%\description
% Returns a reflection matrix, i.e., a matrix that changes the handedness
% of the ith axis (where i=1: x-axis, i=2: y-axis, and i=3: z-axis)
% when multipliying it with a vector.
%
%\seealso{vector, Vector_Type, matrix33_new}
%!%-
{
    variable ax;
    
    switch(_NARGS) {
	case 1: ax=();
    }
    {
	help(_function_name());
	return;
    }

    ax=int(ax);
 
    if (ax<1 || ax>3) {
	throw UsageError,sprintf("%s: axis must be 1,2 or 3\n",_function_name());
    }

    if (ax==1) {
	return matrix33_diag(-1.,+1.,+1.);
    }
    if (ax==2) {
	return matrix33_diag(+1.,-1.,+1.);
    }
    return matrix33_diag(+1.,+1.,-1.);
    
}
    
%%%%%%%%%%%%%%%%%
define matrix33_rot()
%%%%%%%%%%%%%%%%%
%!%+
%\function{matrix33_rot}
%\synopsis{return a standard rotation matrix about the x-, y-, or z-axis}
%\usage{ Matrix33_Type=matrix33_rot(i,angle;qualifiers);}
%\qualifiers{
% \qualifier{deg}{angle is given in deg [default: radians]}
%}
%\description
% Returns a rotation matrix to transform a column-3 vector from
% one cartesian coordinate system to another. The new coordinate
% system is given by rotating the original system in a counter
% clockwise way around the ith axis (where i=1: x-axis,
% i=2: y-axis, and i=3: z-axis)
%
% The nomenclature follows Kaplan et al, The IAU Resolutions
% on Astronomical Reference Systems, Time Scales, and Earth
% Rotation Models, USNO circular 179, 2005.
%
%\seealso{vector, Vector_Type, matrix33_new}
%!%-
{
    variable ax,ang;
    
    switch(_NARGS) {
	case 2: (ax,ang)=();
    }
    {
	help(_function_name());
	return;
    }

    if (ax<1 || ax>3) {
	throw UsageError,sprintf("%s: axis must be 1,2 or 3\n",_function_name());
    }
    
    variable si,co;
    if (qualifier_exists("deg")) {
	(si,co)=sincos(ang*PI/180.);
    } else {
	(si,co)=sincos(ang);
    }

    ax=int(ax);

    if (ax==1) {
	return matrix33_new(1.,0.,0.,0.,co,si,0.,-si,co);
    }
    if (ax==2) {
	return matrix33_new(co,0.,-si,0.,1.,0.,si,0.,co);
    }
	
    return matrix33_new(co,si,0.,-si,co,0.,0.,0.,1.);
}

% Operator overloading
#ifexists __add_unary
__add_binary("*",Vector_Type, &matrix33_mat_mul_vector, Matrix33_Type, Vector_Type);
__add_binary("*",Matrix33_Type, &matrix33_mat_mul_mat, Matrix33_Type, Matrix33_Type);
__add_binary("*",Matrix33_Type, &matrix33_mat_mul_real, Matrix33_Type, Any_Type);
__add_binary("*",Matrix33_Type, &matrix33_real_mul_mat, Any_Type,Matrix33_Type);

__add_binary("/",Matrix33_Type, &matrix33_mat_div_mat, Matrix33_Type, Matrix33_Type);
__add_binary("/",Matrix33_Type, &matrix33_mat_div_real, Matrix33_Type, Any_Type);
__add_binary("/",Matrix33_Type, &matrix33_real_div_mat, Any_Type,Matrix33_Type);

__add_binary("+",Matrix33_Type, &matrix33_mat_add_mat, Matrix33_Type, Matrix33_Type);
__add_binary("-",Matrix33_Type, &matrix33_mat_sub_mat, Matrix33_Type, Matrix33_Type);
__add_unary("-",Matrix33_Type, &matrix33_chs, Matrix33_Type);

__add_string(Matrix33_Type,&matrix33_as_string);

% addition to the vector type
__add_binary("/",Vector_Type, &vector_div_scalar, Vector_Type, Any_Type);

#endif
