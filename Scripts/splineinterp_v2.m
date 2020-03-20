function [out,fitted]=splineinterp_v2(in,type)

% function [out,fitted]=splineinterp_v2(in,'type')
% Description: 	Fills in NaN points with the result of a cubic spline 
%	       	interpolation.  Marks fitted points with a '1' in a new,
%	       	final column for identification as false points later on.
%	       	This function is intended to work with 3-D points output
%	       	from the 'reconfu' Kinemat function.  Points marked with
%					a '2' were not fitted because of a lack of data
%	
%					'type' should be either 'nearest','linear','cubic' or 'spline'
%
%					Note: the 'fitted' return variable is only 1 column no matter
%					how many columns are passed in 'in', 'fitted' reflects _any_
%					fits performed on that row in any column of 'in'
%
% Version History:
% 1.0, 4/30/03 - Ty Hedrick, derived from splineinterp.m

if exist('type','var')==false
  type='spline';
end

fitted(1:size(in,1),1)=0; % initialize the fitted output matrix

for k=1:size(in,2) % for each column
	Y=in(:,k); % the Y (function resultant) value is the column of interest
	X=[1:1:size(Y,1)]'; % X is just a linearly increasing sequence of the same length as Y

	Xi=X; Yi=Y; % duplicate X and Y and use the duplicates to mess with

	nandex=find(isnan(Y)==1); % get an index of all the NaN values
	fitted(nandex,1)=1; % set the fitted matrix based on the known NaNs

	Xi(nandex,:)=[]; % delete all NaN rows from the interpolation matrices
	Yi(nandex,:)=[]; 

	if size(Xi,1)>=1 % check that we're not dealing with all NaNs
		Ynew=interp1(Xi,Yi,nandex,type,'extrap'); % interpolate new Y values
		in(nandex,k)=Ynew; % set the new Y values in the matrix
		nandex2=find(isnan(Ynew)); % check for remaining NaNs
		if isempty(nandex2)==0
			disp('Interpolation error, try the linear option')
			break
		end
	else
		% only NaNs, don't interpolate
	end

end

out=in; % set output variable
