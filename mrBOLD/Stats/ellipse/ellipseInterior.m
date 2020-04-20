function [img, nSamples] = ellipseInterior(varargin)
% Return an image (matrix) marking the interior of an ellipse
%
% Syntax
%   [img, nSamples] = ellipseInterior(varargin)
%
% Inputs
%   N/A
%
% Optional key/value pairs
%   center  - Center of the ellipse
%   sigma   - Sigma major and minor as a 2-vector
%   theta   - Angle of sigma major from the x-axis (counter clockwise)
%
% Returns
%   img:  1 in the interior and 0 in the exterior
%   nSamples:  Number of interior samples
%
% Description
%   We start with an ellipse with its major axis aligned to the
%   x-axis.  We then rotate (counter clockwise) by an amount theta.
%
%  This is the equation for the contour of the ellipse
%
%     1 = A*(x-h)^2 + 2B*(x-h)*(y-k) + C*(y-k)^2
% 
%  The quadratic form is Q = [A B; B C];
%  We test that the parameters are valid (i.e., Q is positive-definite
%  (i.e., Q = M*M') by 
%
%    A > 0
%    det(Q) > 0
%
%  We convert from sigma(1), sigma(2), theta to Q and inversely using
%
%        Q = Rotate(theta)'*[diag(a^2,b^2)]*Rotate(theta)
%{
%  [U,S,V] = svd(Q)
%  Figure out theta from U and get a, b from sqrt(S)
%  Since
%      rotMat = [cos(theta) -sin(theta); -sin(theta) -cos(theta)];
%      theta = acos(U(1,1))
%
% Some experimenting
%
% It must be a > b for major/minor axes
a = 3; b = 2; theta = pi/6;
rotMat = [cos(theta) -sin(theta); -sin(theta) -cos(theta)];
Q = rotMat' * diag([a^2, b^2]) * rotMat;

[U,S,V] = svd(Q);
abs(U) - abs(rotMat)  % Not sure why there can be a sign difference
thetaEst = min(acos(U(1,1)),acos(-1*U(1,1)));
theta - thetaEst
%}
%
% Notes:
%
%  https://math.stackexchange.com/questions/264446/the-fastest-way-to-obtain-orientation-%CE%B8-from-this-ellipse-formula
%
% Wandell, January 13 2020
% 
% See also
%    ellipsePlot()

% Examples:
%{
   img = ellipseInterior;
   mrvNewGraphWin; imagesc(img); axis equal
%}
%{
   samples = [-3:0.1:3];
   [img, nSamples]  = ellipseInterior('center',[1 2],'spatial samples',samples);
   [img2, nSamples] = ellipseInterior('center',[0.5 2],'spatial samples',samples);

   % mrvNewGraphWin; imagesc(img); axis image
   % mrvNewGraphWin; imagesc(img2); axis image
   overlap = dot(img(:), img2(:))/nSamples;
   fprintf('Overlap is %f\n',overlap);
%}
%{   
   samples = [-10:0.1:10];
   sigma = [3,1];
   [img, nSamples]   = ellipseInterior('center',[0 0],'sigma',sigma,'spatial samples',samples);
   [img2, nSamples]  = ellipseInterior('center',[-1 -4],'sigma',sigma,'spatial samples',samples);
   mrvNewGraphWin; imagesc(samples,samples,img); axis image
   mrvNewGraphWin; imagesc(samples,samples,img2); axis image
   overlap = dot(img(:), img2(:))/nSamples;
   fprintf('Overlap is %f\n',overlap);
%}
%{
   img = ellipseInterior('center',[1 1],'quadratic',0.3*eye(2));
   mrvNewGraphWin; imagesc(img);
%}
%% Input parameters

varargin = mrvParamFormat(varargin);

p = inputParser;
p.addParameter('center',[0 0],@isvector);
p.addParameter('spatialsamples',(-3:0.05:3),@isvector);
vFunc = @(x)(length(x) == 2 && x(1) >= x(2) && isnumeric(x));
p.addParameter('sigma',[1 1],vFunc);   % Length in degrees
p.addParameter('theta',0,@isvector);   % Radians

p.parse(varargin{:});
c = p.Results.center;
samples = p.Results.spatialsamples;
sigma   = p.Results.sigma;
theta   = p.Results.theta;

%%  Test that we have a true ellipse formula

rotMat = [cos(theta) -sin(theta); -sin(theta) -cos(theta)];
Q = rotMat' * diag([1/sigma(1)^2, 1/sigma(2)^2]) * rotMat;
if Q(1,1) <= 0 || det(Q) <= 0 || Q(1,2) ~= Q(2,1)
    error('Q is not positive definite');
end

%% Create the spatial samples and compute the values

[X,Y] = meshgrid(samples,samples);

X = X - c(1);
Y = Y - c(2);
V = Q(1,1)*X.^2 + 2*Q(1,2)*X.*Y + Q(2,2)*Y.^2;
% mrvNewGraphWin; mesh(V)

%% Binarize
img = zeros(size(X));
img(V<=1) = 1;

% mrvNewGraphWin; imagesc(img)

if nargout > 1
    nSamples = sum(img(:));
end

end