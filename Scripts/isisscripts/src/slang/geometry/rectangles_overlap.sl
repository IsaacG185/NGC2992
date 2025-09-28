define rectangles_overlap (src,clp)
%!%+
%\function{rectangles_overlap}
%\synopsis{Checks whether two rectangles overlap}
%\usage{res=rectangles_overlap(src,clp)}
%\description
%
% This function checks whether the two rectangles src and clp
% overlap (return value=1) or not (return value =0).
%
% The rectangles are defined by (xmin,ymin,xmax,ymax)
% either as a 4 element array in this order or as a
% struct with these tags. Both boxes must be defined
% using the same format.
%
%!%-
{
    if (typeof(src)!=typeof(clp)) {
        throw UsageError,"%s: src and clp must have the same type!",_function_name();
    }

    variable xmin,xmax,ymin,ymax;
    if (typeof(src)==Array_Type) {
        %  (sxmax<=cxmin || sxmin>=cxmax)
        if (src[2]<=clp[0] || src[0]>=clp[2]) {
            return 0;
        }
        
        % if (symax<=cymin || symin>=cymax)
        if (src[3]<=clp[1] || src[1]>=clp[3]) {
            return 0;
        }
        return 1;
    }

    if (src.xmax<=clp.xmin || src.xmin>=clp.xmax) {
        return 0;
    }
        
    if (src.ymax<=clp.ymin || src.ymin>=clp.ymax) {
        return 0;
    }

    return 1;

}
