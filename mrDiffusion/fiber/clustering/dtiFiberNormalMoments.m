function [mu, sigmamx]=dtiFiberNormalMoments(fiber)
%9-feature vector representation of a cloud formed by points along the
%fiber which is 3xN long
%Output: vector of mean, plus vector of low-diag covariance matrix read row
%by row.
%ER 2007
mu=mean(fiber');
sigmaSq=cov(fiber'); 
sigmamx=[sigmaSq(1, 1) sigmaSq(2, 1) sigmaSq(2, 2) sigmaSq(3, 1) sigmaSq(3, 2) sigmaSq(3, 3) ];