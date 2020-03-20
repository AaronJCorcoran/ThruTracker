function [rho] = radCurve(xyz_d1,xyz_d2)

% function [rho] = radCurve(xyz_d1,xyz_d2)
%
% Calculates instantaneous radius of curvature for xyz from its first and
% second derivatives.
%
% See http://en.wikipedia.org/wiki/Radius_of_curvature_%28applications%29
%
% Ty Hedrick Sept. 22, 2010

% init output
rho(1:numel(xyz_d1(:,1)),1)=NaN;

for i=1:numel(xyz_d1(:,1))
  rho(i,1)=rnorm(xyz_d1(i,:)).^3./((rnorm(xyz_d1(i,:)).^2.* ...
    rnorm(xyz_d2(i,:)).^2-(xyz_d1(i,:)*xyz_d2(i,:)').^2).^0.5);
end