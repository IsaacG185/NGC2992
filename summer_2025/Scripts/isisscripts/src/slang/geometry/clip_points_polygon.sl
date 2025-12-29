define clip_points_polygon() 
%!%+
%\function{clip_points_polygon}
%\synopsis{Clip points against a polygon}
%\usage{(xc,yc)=clip_points_polygon(x,y,xp,yp)}
%\altusage{clipped=cohen_sutherland(points,poly)}
%\qualifiers{
% \qualifier{evenodd}{use the even-odd method to determine }
% \qualifier{crossing}{use the crossing number method}
% \qualifier{winding}{use the winding number method (the default)}
%}
%
%\description
% This function clips points defined by (x,y), where x and y can be arrays,
% against a closed polygon defined by the arrays (xp, yp) and returns the
% clipped points (xc,yc) where xc, yc are arrays (which can be empty
% if all points are outside of the polygon). Here, a closed polygon
% means that xp[0]==xp[-1] and yp[0]==yp[-1].
%
% Alternatively, the points and polygon can be defined as structs,
% where points=struct{ x=[], y=[] } and where the polygon is defined
% as poly=struct{x=xp,y=yp}
%
% The qualifiers define what to consider the "inside" of the polygon.
%
%\seealso{clip_points_rectangle, greiner_hormann, point_in_polygon}
%
%!%-
{
    variable src,clp;
    variable xx,yy,vx,vy;

    variable stru=0;
    if (_NARGS == 2 ) {
        (src,clp)=();
        stru=1;
        xx=src.x;
        yy=src.y;
        vx=clp.x;
        vy=clp.y;
    } else {
        if (_NARGS == 4 ) {
            (xx,yy,vx,vy)=();
        } else {
            throw UsageError,"clip_points_polygon: Use either 2 or 4 arguments\n";
        }
    }

    variable rx={};
    variable ry={};
    variable i;
    _for i(0,length(xx)-1,1) {
        if (point_in_polygon(xx[i],yy[i],vx,vy;;__qualifiers())) {
            list_append(rx,xx[i]);
            list_append(ry,yy[i]);
        }
    }

    if (length(rx)==0) {
        if (stru) {
            return struct {x=Double_Type[0],y=Double_Type[0]};
        }
        return (Double_Type[0],Double_Type[0]);
    }
    
    list_to_array(xx);
    list_to_array(yy);

    if (stru) {
        return struct{x=xx,y=yy};
    }

    return (xx,yy);
}
