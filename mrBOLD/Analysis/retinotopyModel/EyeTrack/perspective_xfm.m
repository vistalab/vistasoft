function [Xt xfm] = perspective_xfm(X,Y)
% perspective_xfm - 2D perspective transformation
%
% Xt = perspective_xfm(X,Y)
%
% X,Y : input matrix (nx2) giving the each points (n) coordinates
% Xt  : X transformed to match Y
% xfm : tranformation matrices (3x3 and 1x3)
%
% 2008/03 SOD: after A Plane Measuring Device by A. Criminisi, I. Reid, and
% A. Zisserman

% input check
if ~exist('X','var') || isempty(X), error('Need X'); end
if ~exist('Y','var') || isempty(Y), error('Need Y'); end
if ~all(size(X) == size(Y)), error('X and Y need to be the same size'); end

% some variables needed
n   = size(Y,1);
my1 = ones(n,1);
my0 = zeros(n,3);

% compute xfm
B = [ X my1 my0  -X(:,1).*Y(:,1) -X(:,2).*Y(:,1) ...
      my0 X my1  -X(:,1).*Y(:,2) -X(:,2).*Y(:,2)];
B = reshape (B', 8 , n*2)';

D = reshape (Y', n*2 , 1 );
l = inv(B' * B) * B' * D;
A = reshape([l(1:6)' 0 0 1 ],3,3)';
C = [l(7:8)' 1];


% now transform
X  = [X my1]';
Xt = ((A*X) ./ (ones(3,1)*(C*X)))';
Xt = Xt(:,1:2);

% xfm matrices
xfm = [A;C];
return


