function [Xt xfm] = linear_xfm(X,Y)
% linear_xfm - 2D linear transformation
%
% Xt = perspective_xfm(X,Y)
%
% X,Y : input matrix (nx2) giving the each points (n) coordinates
% Xt  : X transformed to match Y
% xfm : tranformation matrices (3x3 and 1x3)
%
% 2008/03 SOD: wrote it

% input check
if ~exist('X','var') || isempty(X), error('Need X'); end
if ~exist('Y','var') || isempty(Y), error('Need Y'); end
if ~all(size(X) == size(Y)), error('X and Y need to be the same size'); end

% some variables needed
n   = size(Y,1);
my1 = ones(n,1);

% padd X and Y
X = [X my1];
Y = [Y my1];

% compute xfm
xfm = pinv(X)*Y;

% compute Xt
Xt = X*xfm;
Xt = Xt(:,1:2);

return