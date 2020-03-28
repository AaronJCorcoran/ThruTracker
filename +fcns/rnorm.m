function [norms] = rnorm(mat)

norms=dot(mat',mat').^0.5';