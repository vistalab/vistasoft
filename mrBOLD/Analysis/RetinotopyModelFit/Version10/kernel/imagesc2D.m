%==============================================================================
function ih = imagesc2D(B,Omega,m,varargin)

colmap = [];

% overwrite default parameter 
for k=1:1:length(varargin)/2,
  %disp([varargin{2*k-1},'=varargin{',int2str(2*k),'};']);
  eval([varargin{2*k-1},'=varargin{',int2str(2*k),'};']);
end;

% compute pixel size and generate a regular grid
h  = Omega./m;
z1 = h(1)/2:h(1):Omega(1);
z2 = h(2)/2:h(2):Omega(2);        

% we are now ready to use MATLAB's image           
ih = imagesc(z1,z2,reshape(B,m)');

axis image; axis xy                     % apply some nice axis 
if ~isempty(colmap), colormap(colmap);  end;
return;

%==============================================================================
