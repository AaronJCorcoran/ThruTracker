function d=measPolyLine_v1(x,y,z);

% function d=measPolyLine_v1(x,y);
%
% Calculates the total distance along a line consisting of segments. The
% measurement unit is equivalent to the xy input units.
%
% Input: 
%       X and Y values of each line segment
% Output:
%       Total distance (adding lengths of all line segments)
%
% 20180125 - Pranav Khandelwal

xyz_diff=diff([x(:) y(:) z(:)]);
d=nansum(sqrt(nansum(xyz_diff.*xyz_diff,2)));
end