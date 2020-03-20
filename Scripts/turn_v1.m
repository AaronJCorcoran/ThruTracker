function [rho,cf] = turn_v1(xyz_d1,xyz_d2)

% function [rho,cf] = turn_v1(xyz_d1,xyz_d2)
%
% Calculates the instantaneous radius of curvature and the centripetal
% force for track points.
% 
% Authors - Pranav Khandelwal, Ty Hedrick

rho = radCurve(xyz_d1(1:end-1,:),xyz_d2);
cf = (rnorm(xyz_d1(1:end-1,:)).^2./rho)/9.81;
end