function y = nanmedian(x,dim)
%Replacement for Matlab statistics toolbox nanmedian function
%
%   m = nanmean(x,dim)
%
% Vistasoft, Stanford team.


if nargin == 1
    y = prctile(x, 50);
else
    y = prctile(x, 50,dim);
end
