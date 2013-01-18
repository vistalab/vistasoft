function showSearchSpace(model);
% showSearchSpace - function to show search space
% to evaluate whether this space is smooth or not.
%
%

% 12/2006 SOD: wrote it.

if nargin < 1,
  help(mfilename);
  return;
end;

if ~isfield(model,'allrms'),
  error('Undefined field allrms.');
else,
  a = model.allrms;
end


params = rmDefineParameters;


% copied from mrDefineParameters
nsteps  = 16;         % must be even so we pass through 0     
maxRF   = params.analysis.fieldSize;
maxXY   = params.analysis.fieldSize+maxRF;
sigma   = [1:nsteps]./nsteps.*maxRF;
x0      = [-maxXY:maxXY./nsteps:maxXY];
y0      = [-maxXY:maxXY./nsteps:maxXY];
[x, y, z] = meshgrid(x0,y0,sigma);
x = x(:); y = y(:); z = z(:);
dist = sqrt(x.^2+y.^2);
keep = find(dist<=maxXY & dist-z<=maxRF);

% results variable
f=ones(size(x(:))).*Inf;

% fill search space and reshape
f(keep)=a';
b=reshape(f,[33 33 16]);

b(b==Inf)=max(isfinite(b(:)));

% show search space
img=makeMontage(b,1:16);
figure; imagesc(img); colormap(spectral); axis equal xy; axis off;
