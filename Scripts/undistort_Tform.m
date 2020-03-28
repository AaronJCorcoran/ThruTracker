function [uvdd] = undistort_Tform(uv,T)

% function [uvdd] = undistort_Tform(uv,T)
%
% inputs:
%  uv - array of pixel coordinates, distorted
%  T.tdata(1:2) - focal length
%  T.tdata(3:4) - principal point
%  T.tdata(5:9) - nonlinear distortion coefficients
%  T.tdata(10) - number of interations
%
% outputs:
%  uvdd - array of pixel coordinates, undistorted
%
% Iteratively applies undistortion coefficients to estimate undistorted
% pixel coordinates from observation of distorted pixel coordinates. This
% version setup for use with MATLAB's tform routines

% break out packed variables
tdata = T.tdata;
f = mean(tdata(1:2));
UoVo = tdata(3:4);
nlin = tdata(5:9);
niter = tdata(10);

% create normalized points from pixel coordinates
uvn = (uv - repmat(UoVo,size(uv,1),1))./f;

uvnd = uvn;

% undistort (niter iterations)
for i=1:niter
  r2=rnorm(uvnd).^2; % square of the radius
  rad = 1 + nlin(1)*r2 + nlin(2)*r2.^2 + nlin(5)*r2.^3; % radial distortion
  
  % tangential distortion
  tan = [2*nlin(3).*uvnd(:,1).*uvnd(:,2) + nlin(4)*(r2 + 2*uvnd(:,1).^2)];
  tan(:,2) = nlin(3)*(r2 + 2*uvnd(:,2).^2) + 2*nlin(4).*uvnd(:,1).*uvnd(:,2);
  
  uvnd = (uvn - tan)./repmat(rad,1,2);
end

% restore pixel coordinates
uvdd = uvnd*f + repmat(UoVo,size(uv,1),1);