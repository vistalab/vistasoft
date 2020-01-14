function img = ellipseInterior(varargin)
% Return an image (matrix) marking the interior of an ellipse
%
% Syntax
%   img = ellipseInterior('center',[0,0],'quadratic',eye(2))
%
% Description
% We use this equation for the contour of the ellipse
%
%   1 = A*(x-h)^2 + 2B*(x-h)*(y-k) + C*(y-k)^2
% 
% where the quadratic form is Q = [A B; B C];
% 
% Q must be positive-definite (i.e., Q = M*M'). We can test for
% positive definite by 
%
%    A > 0
%    det(Q) > 0
%
% We need a method for converting from a,b,theta to Q and inversely
%
%        Q = Rotate(theta)'*[diag(a^2,b^2)]*Rotate(theta)
%
%  [U,S,V] = svd(Q)
%  Figure out theta from U and get a, b from sqrt(S)
%  Since
%      rotMat = [cos(theta) -sin(theta); -sin(theta) -cos(theta)];
%      theta = acos(U(1,1))
%
% Some experimenting
%
% a = 2; b = 3; theta = pi/3;
% rotMat = [cos(theta) -sin(theta); -sin(theta) -cos(theta)];
% Q = rotMat* diag([a^2,b^2]) * rotMat';

%[U,S,V] = svd(Q);
%
% 
%  https://math.stackexchange.com/questions/264446/the-fastest-way-to-obtain-orientation-%CE%B8-from-this-ellipse-formula
%
% Wandell, January 13 2020
% 
% See also
%
% Examples:
%{
   img = ellipseInterior;
   mrvNewGraphWin; imagesc(img);
%}
%{
   img = ellipseInterior('center',[1 2]);
   mrvNewGraphWin; imagesc(img);
%}
%{
   img = ellipseInterior('center',[1 1],'quadratic',0.3*eye(2));
   mrvNewGraphWin; imagesc(img);
%}
%% 
varargin = mrvParamFormat(varargin);

p = inputParser;
p.addParameter('center',[0 0],@isvector);
p.addParameter('quadratic',eye(2),@ismatrix);
p.addParameter('spatialsamples',(-3:0.05:3),@isvector);

p.parse(varargin{:});
c = p.Results.center;
Q = p.Results.quadratic;
samples = p.Results.spatialsamples;

%%
if Q(1,1) <= 0 || det(Q) <= 0 || Q(1,2) ~= Q(2,1)
    error('Q is not positive definite');
end

[X,Y] = meshgrid(samples,samples);

X = X - c(1);
Y = Y - c(2);
V = Q(1,1)*X.^2 + 2*Q(1,2)*X.*Y + Q(2,2)*Y.^2;
% mrvNewGraphWin; mesh(V)

%% Binarize
img = ones(size(X));
img(V<=1) = -1;

% mrvNewGraphWin; imagesc(img)

end