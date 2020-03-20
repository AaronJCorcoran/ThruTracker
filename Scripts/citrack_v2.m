function [spts,d1,d2]=citrack_v2(pts,ci,camFreq,varargin)
%
% function [d1_ci,d2_ci,tpts]=citrack_v2(pts,ci,camFreq)
%
% calculating the position, velocity and acceleration on the raw data with
% the given confidence interval.
%
% Input: 
%       pts - xyzpts 
%       ci - xyzCI
%       camFreq - recording fps
%       interp - 'y' or 'n', default is 'n'
% Output:
%       spts - smooth pts, if interp is set to 'y' then smooth and
%       interpolated
%       d1 - first order differential or velocity
%       d2 - second order differentail or acceleration
%
% 20180425 - Pranav Khandelwal

%% setup parser
default.interp='n';
p=inputParser;
addParameter(p,'interp',default.interp);
% parse user inputs
parse(p,varargin{:});
% parsed inputs
interp_opt=p.Results.interp;

%% setup smoother with interpolation

% CI smoother
%sd=ci./1.96; % use to filter to 1 standard deviation (as in DLTdv)
sd=ci; % use to filter to a 95% CI
w=(1./(sd./repmat(min(sd),size(sd,1),1)));
tol=nansum(w.*(sd.^2)); % yes, it is OK that the weighting function effectively reduces the tol
% Calculations
% position
spts=splineDerivativeKE2(pts,tol,w,0);
% velocity
d1=splineDerivativeKE2(pts,tol,w,1)*camFreq;
% acceleration
d2=splineDerivativeKE2(pts,tol,w,2)*camFreq^2;

% spline interpolation
if strcmpi(interp_opt,'y');
    spts=splineinterp_v2(spts);
    d1=splineinterp_v2(d1);
    d2=splineinterp_v2(d2);
end