function diceC = ellipseDice(E1,E2,varargin)
% Compute the percentage overlap of a pair of ellipses
%
% Syntax
%   diceC = ellipseDice(E1,E2,varargin)
%
% Input
%   E1, E2 - Two structs that contain the ellipse parameters
%       .center
%       .sigma
%       .theta
% 
% Optional key/value pairs
%   spatial samples - vector of the sample points in deg (default -10:0.1:10);
%   show -  Create an image showing the overlap
%
% Outputs
%   diceC - Dice coefficient = 2*areaOfE1E2Intersection / eArea1 + eArea2 ;
%
% Author, Wandell January 17, 2020 
%
% See also
%   ellipseInterior, ellipsePoints, ...


% Examples:
%{
   E1.center = [0,0]; E1.sigma = [3,1]; E1.theta = pi;
   E2.center = [-1,0]; E2.sigma = [3,1]; E2.theta = pi/2;
   diceC = ellipseDice(E1,E2,'show',true);
%}
%{
   E1.center = [0,0]; E1.sigma = [1,1]; E1.theta = pi;
   E2.center = [-1,0]; E2.sigma = [3,3]; E2.theta = pi/2;
   diceC = ellipseDice(E1,E2,'show',true);
%}
%{
   E1.center = [0,0]; E1.sigma = [1,1]; E1.theta = pi;
   E2.center = [0,0]; E2.sigma = [1,1]; E2.theta = pi/2;
   diceC = ellipseDice(E1,E2,'show',true);
%}

%% Input parameters

% Remove spaces and force lower case
varargin = mrvParamFormat(varargin);

p = inputParser;

% Validation function
vFunc = @(x)(isstruct(x) && isfield(x,'center') && isfield(x,'sigma') && isfield(x,'theta'));
p.addRequired('E1',vFunc);
p.addRequired('E2',vFunc);

p.addParameter('spatialsamples',(-10:0.05:10),@isvector);
p.addParameter('show',false,@islogical);

p.parse(E1,E2,varargin{:});

samples = p.Results.spatialsamples;
show    = p.Results.show;

%% Compute

% 1 inside, 0 outside.
[img1, nSamples] = ellipseInterior('center',E1.center, ...
    'sigma',E1.sigma, ...
    'theta',E1.theta',...
    'spatial samples',samples);
img2   = ellipseInterior('center',E2.center,...
    'sigma',E2.sigma,...
    'theta',E2.theta,...
    'spatial samples',samples);

%%
overlapArea = sum(img1(:) .* img2(:));
diceC = 2*overlapArea/ (sum(img1(:)) + sum(img2(:)));

if show
    img = img1 + img2;
    mrvNewGraphWin; colormap([0.2 0.3 0.4; 0.6 0.6 0.6; 1 1 1]);
    image(samples,samples,img + 1); axis image;
    xlabel('Deg'); ylabel('Deg'); grid on
end

end

