define xfig_get_normalized_x_position(p,xval) {
%!%+
%\function{xfig_get_normalized_x_position}
%\synopsis{Compute normalized (world0) x-position from world1 x-position}
%\usage{xnorm=xfig_get_normalized_x_position(p,xval)}
%\description
%For a given xfig plot p and x-coordinate value xval given in the world1
%coordinate system, compute the corresponding normalized world0 x-value.
%
%This function is necessary since the xfig module does not export
%its world normalization functions. It is heavily based on these.
%
%\seealso{xfig_get_normalized_position,xfig_get_normalized_y_position}
%!%-
    variable xwcs=p.plot_data.x1axis.wcs_transform;
    variable cd=xwcs.client_data;
    variable ww=double(p.get_world());
    variable f=xwcs.wcs_func;
    variable t0 = (@f)(ww[0], cd);
    variable t1 = (@f)(ww[1], cd);
    variable xnorm=((@f)(double(xval), cd) - t0)/(t1-t0);
    return xnorm;
}

define xfig_get_normalized_y_position(p,yval) {
%!%+
%\function{xfig_get_normalized_y_position}
%\synopsis{Compute normalized (world0) y-position from world1 y-position}
%\usage{ynorm=xfig_get_normalized_y_position(p,yval)}
%\description
%For a given xfig plot p and y-coordinate value yval given in the world1
%coordinate system, compute the corresponding normalized world0 y-value.
%
%This function is necessary since the xfig module does not export
%its world normalization functions. It is heavily based on these.
%
%\seealso{xfig_get_normalized_position,xfig_get_normalized_x_position}
%!%-
    variable ywcs=p.plot_data.y1axis.wcs_transform;
    variable cd=ywcs.client_data;
    variable ww=double(p.get_world());
    variable f=ywcs.wcs_func;
    variable t0 = (@f)(ww[2], cd);
    variable t1 = (@f)(ww[3], cd);

    variable ynorm=((@f)(double(yval), cd) - t0)/(t1-t0);
    return ynorm;
}

define xfig_get_normalized_position(p,xval,yval) {
%!%+
%\function{xfig_get_normalized position}
%\synopsis{Compute normalized (world0) x,y-position from world1 x,y-position}
%\usage{xnorm=xfig_get_normalized_position(p,xval,yval)}
%\description
%For a given xfig plot p and coordinate values xval,yval given in the world1
%coordinate system, compute the corresponding normalized world0 x,y-position.
%
%This function is necessary since the xfig module does not export
%its world normalization functions. It is heavily based on these.
%
%\seealso{xfig_get_normalized_x_position,xfig_get_normalized_y_position}
%!%-
    variable xwcs=p.plot_data.x1axis.wcs_transform;
    variable ywcs=p.plot_data.y1axis.wcs_transform;
    variable xcd=xwcs.client_data;
    variable ycd=ywcs.client_data;
    variable ww=double(p.get_world());
    variable xf=ywcs.wcs_func;
    variable xt0 = (@xf)(ww[0], xcd);
    variable xt1 = (@xf)(ww[1], xcd);

    variable yf=ywcs.wcs_func;
    variable yt0 = (@yf)(ww[2], ycd);
    variable yt1 = (@yf)(ww[3], ycd);

    variable xnorm=((@xf)(double(xval), xcd) - xt0)/(xt1-xt0);
    variable ynorm=((@yf)(double(yval), ycd) - yt0)/(yt1-yt0);
    return xnorm,ynorm;
}
