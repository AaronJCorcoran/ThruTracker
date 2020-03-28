function [Ddata]=splineDerivativeKE2(data,tol,weights,order)

% function [Ddata]=splineDerivativeKE2(data,tol,weights,order)
%
% Inputs:
%   data - a columnwise data matrix. No NaNs or Infs please.
%   tol - the total error allowed: tol=sum((data-Ddata)^2)
%   weights - weighting function for the error:
%     tol=sum(weights*(data-Ddata)^2)
%   order - the derivative order (note that tol is with respect to the 0th
%     derivative)
%
% Outputs:
%   Ddata - the smoothed function (or its derivative) evaluated across the
%     input data
%
% Uses the spaps function of the spline toolbox to compute the smoothest
% function that conforms to the given tolerance and error weights.
%
% version 2, Ty Hedrick, Feb. 28, 2007


% create a sequence matrix, assume regularly spaced data points
X=(1:size(data,1))';

% set any NaNs in the weight matrix to zero
idw=find(isnan(weights)==true);
weights(idw)=0;

% spline order
sporder=3; % quintic spline, okay for up to 3rd order derivative

% spaps can't handle a weights matrix instead of a weights vector, so we
% loop through each column in data ...
for i=1:size(data,2)
  % initialize output column
  Ddata(:,i) = data(:,i)*NaN;
  
  % Non-NaN index
  idx=find(isnan(data(:,i))==false);

  if numel(idx)>3
    [sp] = spaps(X(idx),data(idx,i)',tol(i),weights(idx,i),sporder);

    % get the derivative of the spline
    spD = fnder(sp,order);

    % compute the derivative values on X
    Ddata(idx,i) = fnval(spD,X(idx));
  end

end