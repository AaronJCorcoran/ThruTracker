function [y z]=circPts(y1,z1,rad)
%the function, must be on a folder in matlab path
a=2*pi*rand;
r=sqrt(rand);
y=(rad*r)*cos(a)+y1;
z=(rad*r)*sin(a);
end