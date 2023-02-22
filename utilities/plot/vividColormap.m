function cmap = vividColormap(varargin)
% VIVID Creates a Personalized Vivid Colormap
%  VIVID(...) Creates a vivid colormap with custom settings
%
%   Inputs:
%       M - (optional) an integer between 1 and 256 specifying the number
%           of colors in the colormap. Default is 128.
%       MINMAX - (optional) is a 1x2 vector with values between 0 and 1
%           representing the intensity range for the colors, which correspond
%           to black and white, respectively. Default is [0.15 0.85].
%       CLRS - (optional) either a Nx3 matrix of values between 0 and 1
%           representing the desired colors in the colormap
%               -or-
%           a string of characters that includes any combination of the
%           following letters:
%               'r' = red, 'g' = green, 'b' = blue
%               'y' = yellow, 'c' = cyan, 'm' = magenta
%               'o' = orange, 'l' = lime green, 'a' = aquamarine
%               's' = sky blue, 'v' = violet, 'p' = pink
%               'k' or 'w' = black/white/grayscale
%
%   Outputs:
%       CMAP - an Mx3 colormap matrix
%
%   Example:
%       % Default Colormap
%       imagesc(sort(rand(200),'descend'));
%       colormap(vividColormap); colorbar
%
%   Example:
%       % Mapping With 256 Colors
%       imagesc(peaks(500))
%       colormap(vividColormap(256)); colorbar
%
%   Example:
%       % Mapping With Full Intensity Range
%       imagesc(peaks(500))
%       colormap(vividColormap([0 1])); colorbar
%
%   Example:
%       % Mapping With Light Colors
%       imagesc(peaks(500))
%       colormap(vividColormap([.5 1])); colorbar
%
%   Example:
%       % Mapping With Dark Colors
%       imagesc(peaks(500))
%       colormap(vividColormap([0 .5])); colorbar
%
%   Example:
%       % Mapping With Custom Color Matrix
%       imagesc(peaks(500))
%       clrs = [1 0 .5; 1 .5 0; .5 1 0; 0 1 .5; 0 .5 1; .5 0 1];
%       colormap(vividColormap(clrs)); colorbar
%
%   Example:
%       % Mapping With Color String
%       imagesc(peaks(500))
%       colormap(vividColormap('roylgacsbvmp')); colorbar
%
%   Example:
%       % Colormap With Multiple Custom Settings
%       imagesc(sort(rand(300,100),'descend'));
%       colormap(vividColormap(64,[.1 .9],'rwb')); colorbar
%
% See also: jet, hsv, gray, hot, copper, bone
%
% Author: Joseph Kirk
% Email: jdkirk630@gmail.com
% Release: 1.0
% Date: 07/25/08


% Default Color Spectrum
clrs = [1 0 0;1 .5 0;1 1 0;0 1 0    % Red, Orange, Yellow, Green
    0 1 1;0 0 1;.5 0 1;1 0 1];      % Cyan, Blue, Violet, Magenta

% Default Min/Max Intensity Range
minmax = [0.15 0.85];

% Default Colormap Size
m = 128;

% Process Inputs
for var = varargin
    input = var{1};
    if ischar(input)
        num_clrs = length(input);
        clr_mat = zeros(num_clrs,3);
        c = 0;
        for k = 1:num_clrs
            c = c + 1;
            switch lower(input(k))
                case 'r', clr_mat(c,:) = [1 0 0];  % red
                case 'g', clr_mat(c,:) = [0 1 0];  % green
                case 'b', clr_mat(c,:) = [0 0 1];  % blue
                case 'y', clr_mat(c,:) = [1 1 0];  % yellow
                case 'c', clr_mat(c,:) = [0 1 1];  % cyan
                case 'm', clr_mat(c,:) = [1 0 1];  % magenta
                case 'p', clr_mat(c,:) = [1 0 .5]; % pink
                case 'o', clr_mat(c,:) = [1 .5 0]; % orange
                case 'l', clr_mat(c,:) = [.5 1 0]; % lime green
                case 'a', clr_mat(c,:) = [0 1 .5]; % aquamarine
                case 's', clr_mat(c,:) = [0 .5 1]; % sky blue
                case 'v', clr_mat(c,:) = [.5 0 1]; % violet
                case {'k','w'}, clr_mat(c,:) = [.5 .5 .5]; % grayscale
                otherwise, c = c - 1;
            end
        end
        clr_mat = clr_mat(1:c,:);
        if ~isempty(clr_mat)
            clrs = clr_mat;
        end
    elseif isscalar(input)
        m = max(1,min(256,round(real(input))));
    elseif size(input,2) == 3
        clrs = input;
    elseif length(input) == 2
        minmax = max(0,min(1,real(input)));
    end
end

% Calculate Parameters
nc = size(clrs,1);  % number of spectrum colors
ns = ceil(m/nc);    % number of shades per color
n = nc*ns;
d = n - m;

% Scale Intensity
sup = 2*minmax;
sub = 2*minmax - 1;
high = repmat(min(1,linspace(sup(1),sup(2),ns))',[1 nc 3]);
low = repmat(max(0,linspace(sub(1),sub(2),ns))',[1 nc 3]);

% Determine Color Spectrum
rgb = repmat(reshape(flipud(clrs),1,nc,3),ns,1);
map = rgb.*high + (1-rgb).*low;

% Obtain Color Map
cmap = reshape(map,n,3,1);
cmap(1:ns:d*ns,:) = [];

