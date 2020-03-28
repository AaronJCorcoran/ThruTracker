function [xyz]=angleaxisRotation(xyz,uvw,theta)

% function [xyz]=angleaxisRotation(xyz,uvw,theta)
%
% Rotates xyz about axis uvw by angle theta
%
% Inputs: xyz - array of xyz coordinates to be rotated
%         uvw - axis to rotate about (must be same length as xyz)
%         theta - angle to rotate through (single value)
%
% Pure MATLAB implementation, no MEX involved
% 
% author - Ty Hedrick

% vectorized method
uvw=uvw./repmat(rnorm(uvw),1,3); % make sure UVW is a matrix of unit vectors

if numel(theta)==1
  xyz=uvw.*(repmat(dot(uvw,xyz,2),1,3))+(xyz-uvw.*(repmat(dot(uvw,xyz,2),1,3))).* ...
  cos(theta)+cross(xyz,uvw,2).*sin(theta);
else
  xyz=uvw.*(repmat(dot(uvw,xyz,2),1,3))+(xyz-uvw.*(repmat(dot(uvw,xyz,2),1,3))).* ...
  repmat(cos(theta),1,3)+cross(xyz,uvw,2).*repmat(sin(theta),1,3);
end