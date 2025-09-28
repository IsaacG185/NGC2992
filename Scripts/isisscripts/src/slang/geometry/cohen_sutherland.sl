
private variable CS_inside=0; % 0000
private variable CS_left=1;   % 0001
private variable CS_right=2;  % 0010
private variable CS_bottom=4; % 0100
private variable CS_top=8;    % 1000

private define cs_outcode(x,y,xmin,ymin,xmax,ymax) {
    %
    % return location of x,y against box xmin,ymin,xmax,ymax
    variable code=CS_inside;
    if (x<xmin) {
        code |= CS_left;
    } else {
        if (x>xmax) {
            code |=CS_right;
        }
    }
    if (y<ymin) {
        code |= CS_bottom;
    } else {
        if (y>ymax) {
            code |=CS_top;
        }
    }
    return code;
}


define cohen_sutherland()
%!%+
%\function{cohen_sutherland}
%\synopsis{Clip a line against a rectangle}
%\usage{(xc0,yc0,xc1,yc1)=cohen_sutherland(x0,y0,x1,y1,xmin,ymin,xmax,ymax)}
%\altusage{clipped=cohen_sutherland(line,box)}
%\description
% This function clips a line defined by the points (x0,y0) and (x1,y1) against
% a box defined by the corner points (xmin,ymin) and (xmax,ymax) and returns
% the clipped line (xc0,yc0) -- (xc1,yc1). The clipped coordinates are set
% to _NaN if the line misses the box.
%
% The line segment and clipping box can be either defined directly by giving the
% coordinates or as structs, In the latter case, the line segment
% is defined as line= struct{ x=[x0,x1], y=[y0,y1] } and the
% rectangular box is defined either as box=struct{x=[xmin,xmax],y=[ymin,ymax]}
% or as box=struct{xmin=xmin,ymin=ymin,xmax=xmax,ymax=ymax}.
%
%\seealso{clip_points_rectangle,clip_points_polygon, clip_polyline_rectangle,greiner_hormann}
%
%!%-
{
    variable x0,y0,x1,y1,xmin,ymin,xmax,ymax;

    variable struret=0;
    
    if ( _NARGS == 2 ) {
        variable p,box;
        (p,box)=();
        x0=p.x[0]; y0=p.y[0];
        x1=p.x[1]; y1=p.y[1];

        if (struct_field_exists(box,"x")) {
            xmin=box.x[0]; xmax=box.x[1];
            ymin=box.y[0]; ymax=box.y[1];
        } else {
            % shp convention for bounding boxes
            xmin=box.xmin; ymin=box.ymin;
            xmax=box.xmax; ymax=box.ymax;
        }

        struret=1;
        
    } else {
        if (_NARGS==8) {
            (x0,y0,x1,y1,xmin,ymin,xmax,ymax)=();
        } else {
            throw UsageError,"cohen_sutherland: Use either 2 or 8 arguments\n";
        }
    }
    
    variable outcode0=cs_outcode(x0,y0,xmin,ymin,xmax,ymax);
    variable outcode1=cs_outcode(x1,y1,xmin,ymin,xmax,ymax);

    variable accept=0;

    while(1) {
        if ( not (outcode0 | outcode1)) {
            % bitwise or is 0: both points are inside the window
            accept=1;
            break;
        } else {
            % bitwise and is not 0: both points are outside the window
            if (outcode0 & outcode1) {
                break;
            } else {
                % both tests failed: calculate the line segment
                % to clip from an outside point to an intersection
                % with the clip edge;

                variable x,y;
                variable outcodeOut = outcode1 > outcode0 ? outcode1 : outcode0;

                % find the intersection point
                if (outcodeOut & CS_top) { %point is above clip window
                    x=x0+(x1-x0)*(ymax-y0)/(y1-y0);
                    y=ymax;
                } else {
                    if (outcodeOut & CS_bottom) { % point is below clip window
                        x=x0+(x1-x0)*(ymin-y0)/(y1-y0);
                        y=ymin;
                    } else {
                        if (outcodeOut & CS_right) { % right of clip window
                            x=xmax;
                            y=y0+(y1-y0)*(xmax-x0)/(x1-x0);
                        } else {
                            if (outcodeOut & CS_left) { % left of clip window
                                x=xmin;
                                y=y0+(y1-y0)*(xmin-x0)/(x1-x0);
                            }
                        }
                    }
                }

                % move outside point to intersection point
                % and move to next pass
                if (outcodeOut==outcode0) {
                    x0=x;
                    y0=y;
                    outcode0=cs_outcode(x0,y0,xmin,ymin,xmax,ymax);
                } else {
                    x1=x;
                    y1=y;
                    outcode1=cs_outcode(x1,y1,xmin,ymin,xmax,ymax);
                }
            }
        }
    }

    if (accept) {
        if (struret) {
            return struct{x=[x0,x1],y=[y0,y1]};
        }
        return (x0,y0,x1,y1);
    }

    % segment is not in the clip window
    if (struret) {
        return struct{x=Double_Type[0],y=Double_Type[0]};
    }
    return (_NaN,_NaN,_NaN,_NaN);
    
}

define clip_polyline_rectangle(src,box) {
%!%+
%\function{clip_polyline_rectangle}
%\synopsis{Clip a polyline against a rectangle}
%\usage{clipped=clip_polyline_rectangle(poly,box)}
%\description
% This function clips the polyline poly=struct{x=[],y=[]}, where x and y are arrays containing
% the points of the polyline, against a rectangle defined by the corner points (xmin,ymin) and
% (xmax,ymax). It returns a list of structs{x,y}, where each list element contains the points of
% a segment of the polygon that is inside the box.
%
%\seealso{clip_points_polygon, clip_polyline_rectangle, cohen_sutherland, greiner_hormann}
%
%!%-

    variable i;

    variable polyli={};
    variable xx={};
    variable yy={};
    
    _for i(0,length(src.x)-2,1) {
        variable seg=cohen_sutherland(struct{x=[src.x[i],src.x[i+1]],
                                             y=[src.y[i],src.y[i+1]]},box);
        % is the segment within the box?
        if (length(seg.x)>0) {
            % append?
            if (length(xx)>0) {
                % start of new segment different from old end point?
                if ((xx[-1]!=seg.x[0]) || yy[-1]!=seg.y[0]) {
                    xx=list_to_array(xx);
                    yy=list_to_array(yy);
                    list_append(polyli,struct{x=xx,y=yy});
                    xx={};
                    yy={};
                }
            }
            list_append(xx,seg.x[0]); list_append(xx,seg.x[1]);
            list_append(yy,seg.y[0]); list_append(yy,seg.y[1]);
        }
    }

    if (length(xx)>0) {
        xx=list_to_array(xx);
        yy=list_to_array(yy);
        list_append(polyli,struct{x=xx,y=yy});
    }

    return polyli;
}

define clip_points_rectangle()
%!%+
%\function{clip_points_rectangle}
%\synopsis{Clip points against a rectangle}
%\usage{(xc,yc)=clip_points_rectangle(x,y,xmin,ymin,xmax,ymax)}
%\altusage{clipped=clip_points_rectangle(points,box)}
%\description
%This function clips the points defined by (x,y), where x and y can be arrays,
%against a rectangle defined by the corner points (xmin,ymin) and (xmax,ymax) and 
%returns the clipped points (xc,yc) where xc, yc are arrays (which can be empty
%if all points are outside of the rectangle).
%
%Alternatively, the points and clipping rectangle can be defined as structs,
%where points=struct{ x=[], y=[] } and where the clipping rectangle is defined
%either as box=struct{x=[xmin,xmax],y=[ymin,ymax]}
%or as box=struct{xmin=xmin,ymin=ymin,xmax=xmax,ymax=ymax}.
%
%
%\seealso{clip_points_polygon, clip_polyline_rectangle, cohen_sutherland, greiner_hormann}
%
%!%-
{
    variable xmin,xmax,ymin,ymax;
    variable struret=0;
    variable xi,yi;
    
    if ( _NARGS == 2 ) {
        variable src,box;
        (src,box)=();
        xi=src.x;
        yi=src.y;

        if (struct_field_exists(box,"x")) {
            xmin=box.x[0]; xmax=box.x[1];
            ymin=box.y[0]; ymax=box.y[1];
        } else {
            % shp convention for bounding boxes
            xmin=box.xmin; ymin=box.ymin;
            xmax=box.xmax; ymax=box.ymax;
        }

        struret=1;
    } else {
        if (_NARGS==6) {
            (xi,yi,xmin,ymin,xmax,ymax)=();
        } else {
            throw UsageError,"clip_points: Use either 2 or 6 arguments\n";
        }
    }

    variable ndx=where(xmin<=xi<xmax && ymin<=yi<ymax);

    if (struret) {
        return struct {x=xi[ndx],y=yi[ndx]};
    }
    return (xi[ndx],yi[ndx]);
}

