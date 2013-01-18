function [xform, fiterr] = affineSolve(A,B);
% Solve the equation coordsA = xform * coordsB for the xform.
%
% Usage: [xform, fiterr] = affineSolve(coordsA,coordsB);
%
% Problem: You have coordinates of the same points in two 
% coordinate spaces, A and B. You want to find a 4x4 affine
% transform matrix that optimally maps between these points.
%
% Sub-problem: Simply dividing coordsA / coordsB returns a 
% 3x3 xform, not a 4x4 affine.
%
% Solution: use this. It uses singular value decomposition to 
% find the rotation, scales (and skews, if the points are not
% really matching), and subtraction to find the translations, 
% and builds a 4x4 affine xform which minimizes the error
% in the above equation.
%
% coordsA and coordsB should be 3xN coordinate matrices with the
% same number of columns. Each column of coordsA should reflect
% the (row, column, slice) of a point in coordinate space A (the
% NEW coordinate space being xformed to), and each column in coordsB
% should be the (row, column, slice) of the SAME POINT in coordinate
% space B (the OLD coordinate space being xformed from).
%
% The optional output argument fiterr is the root mean squared error
% between coordsA and coordsB given the best set of rotations and 
% tanslations. It is a measure of the goodness-of-fit of the xform
% (since, if the points don't really correspond, not all equations
% can be perfectly solved).
% 
% ras, 10/2005.
if nargin<2, help(mfilename); error('Not enough args.'); end

% size + number checks:
if ~isnumeric(A) | ~isnumeric(B), error('Need numeric args.'); end
if size(A,2)~=size(B,2)
    error('Coords should have same # of columns.');
end
if size(A,1)<3 | size(B,1)<3, 
    error('Coords need to be specified in 3 dimensions.')
end

% just curious: does just doing / division work better?
n = size(A, 2);
xform = [A; ones(1, n)] / [B; ones(1, n)];

% % express points relative to center of all points:
% nPoints = size(A,2);
% centeredA = A - repmat(mean(A,2),[1 nPoints]);
% centeredB = B - repmat(mean(B,2),[1 nPoints]);
% 
% % solve for rotation + scales (& skews, if points are bad):
% H = zeros(3,3);
% for i = 1:nPoints
%     H = H + (centeredB(:,i) * centeredA(:,i)');
% end
% [U S V] = svd(H);
% rot = V*(U');
% 
% % solve for translation
% rotatedB = rot * B;
% trans = mean(A,2) - mean(rotatedB,2);
% 
% % build 4x4 affine xform matrix
% xform = [rot trans; 0 0 0 1];
% 
% % force skew to equal 0
% [trans rot scale skew] = affineDecompose(xform);
% skew = [0 0 0];
% xform = affineBuild(trans,rot,scale,skew);
% 
% % return error of fit if requested
% if nargout > 1
% 	xB = xform * [B; ones(1, size(B, 2))];
% 	xB = xB(1:3,:);
% 	fiterr = mean(abs(A - xB).^2);
% end

return
