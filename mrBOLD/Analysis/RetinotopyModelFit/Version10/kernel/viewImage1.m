% JM: 2006/07/19
% viewer for data Ic on domain Omega 


function varargout = viewImage(Ic,Omega,m,varargin);
% this is just output and hence not commented; fell free to improve (-;

global VIEWER VIEWPARA

% default parameter:
fig       = 1;
name      = 'image';
plots     = 1;
sub       = [1,1,1];
figname   = '';

%% overwrite default parameter 
for k=1:1:length(varargin)/2,
  %disp([varargin{2*k-1},'=varargin{',int2str(2*k),'};']);
  eval([varargin{2*k-1},'=varargin{',int2str(2*k),'};']);
end;

if ~plots, return;  end;          % do nothing, just return;

if nargin == 0,
  fprintf('VIEWER = %s\n',VIEWER);
  VIEWPARA
  return;
end;

if isstr(Ic) & strcmp(Ic,'set'),
%   fprintf('set VIEWPARA\n');  
  VIEWPARA = {Omega,m,varargin{:}};
  for j = 1:length(VIEWPARA),
    if strcmp(VIEWPARA{j},'viewer'), 
      VIEWER = VIEWPARA{j+1};  
      break;
    end;
  end;
%   viewImage;
  return;
end;

  
% setup figure
fig = figure(fig); 
subplot(sub(1),sub(2),sub(3)); cla;

if ~isempty(figname),
  set(fig,'numbertitle','off','name',sprintf('[JM-%d]: %s',fig,figname));
end;

% call the viewer
fh = feval(VIEWER,Ic,Omega,m,VIEWPARA{:});
str = sprintf('%s',name);
title(str);

if nargout>0,  varargout{1} = fh;  end;
return;
%==============================================================================


%==============================================================================
function ih = image2D(B,Omega,m,varargin)

colmap = [];

%% overwrite default parameter 
for k=1:1:length(varargin)/2,
  %disp([varargin{2*k-1},'=varargin{',int2str(2*k),'};']);
  eval([varargin{2*k-1},'=varargin{',int2str(2*k),'};']);
end;

% compute pixel size and generate a regular grid
h  = Omega./m;
z1 = h(1)/2:h(1):Omega(1);
z2 = h(2)/2:h(2):Omega(2);        

% we are now ready to use MATLAB's image           
ih = image(z1,z2,reshape(B,m)'); 
axis image; axis xy                     % apply some nice axis 
if ~isempty(colmap), colormap(colmap);  end;
return;

%==============================================================================
function ih = imagesc2D(B,Omega,m,varargin)

colmap = [];

%% overwrite default parameter 
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
function p = volview(I,Omega,m,varargin)

I = reshape(I,m);
% I = flipdim(I,3);
isovalue    = 0;
viewpoint   = [-37.5,30];
facecolor   = .75*[1,1,1];
facealpha   = .8;

%% overwrite default parameter 
for k=1:1:length(varargin)/2,
  %disp([varargin{2*k-1},'=varargin{',int2str(2*k),'};']);
  eval([varargin{2*k-1},'=varargin{',int2str(2*k),'};']);
end;

I(I<isovalue) = 0;

p(1) = patch(isosurface(I,isovalue));

switch computer,
case 'PCWIN',
  set(p(1),...
    'FaceColor',facecolor,...
    'EdgeColor','none');
otherwise,
  set(p(1),...
    'FaceColor',facecolor,...
    'EdgeColor','none',...
    'FaceAlpha',facealpha);
end;

isonormals(I,p(1))

p(2) = patch(isocaps(I,isovalue));

set(p(2),...
  'FaceColor','interp',...
  'EdgeColor','none');

view(viewpoint); 
axis equal
axis([1,size(I,2),1,size(I,1),1,size(I,3)]);
camlight; lighting phong
material dull
drawnow
%==============================================================================

%==============================================================================
function ih = montage(I,Omega,m,varargin)

I = reshape(I,m);

threshold = 0;
framesx   = [];
framesy   = [];
direction = 'x';
number    = 'off';
colmap    = [];
%% overwrite default parameter 
for k=1:1:length(varargin)/2,
  %disp([varargin{2*k-1},'=varargin{',int2str(2*k),'};']);
  eval([varargin{2*k-1},'=varargin{',int2str(2*k),'};']);
end;

if threshold ~= 0,
  I(I<threshold) = 0;
end;

I = squeeze(I);
l = length(size(I));

fig = gcf;
switch l,
  case 1,
    hh = plot(1:size(I,1),I);
  case 2,
    hh = subimage(I,colmap);
    if ~isempty(colmap), colormap(colmap); end;
  case 3,
    [m1,m2,m3] = size(I); 
    
    switch direction,
      case 'x',
        aa = m1; b1 = m2; b2 = m3; I1 = 1:m2; I2 = 1:m3;
      case 'y',
        aa = m2; b1 = m1; b2 = m3; I1 = 1:m1; I2 = 1:m3;
      case 'z',
        aa = m3; b1 = m1; b2 = m2; I1 = 1:m1; I2 = 1:m2;
        
      otherwise, jmerror(direction);
    end;
    
    if isempty(framesx) & isempty(framesy),
      framesx = ceil(sqrt(aa));  
      framesy = ceil(aa/framesx);
    elseif isempty(framesx),
      framesx = ceil(aa/framesy);
    else
      framesy = ceil(aa/framesx);
    end;
    
    %   fprintf('image is %dx%dx%d, frames [%d,%d]\n',...
    %     m1,m2,m3,framesx,framesy);
    
    B = zeros(b1*framesx,b2*framesy);
    
    a1 = 0; a2 = 0;
    for j=1:aa,      
      switch direction,
        case 'x',  P = squeeze(I(j,:,:));
        case 'y',  P = squeeze(I(:,j,:));
        case 'z',  P = squeeze(I(:,:,j));
      end;      
      B(a1+I1,a2+I2) = P;
      a2 = a2 + b2;
      if ~rem(j,framesy), a1 = a1 + b1; a2 = 0; end;
    end;
    
    ih = image(B);
    if ~isempty(colmap), colormap(colmap); end;
    hold on
    
    if strcmp(number,'on'),
      a1 = 0; a2 = 0;
      for j=1:aa,
        text(a2+10,a1+20,['#',int2str(j)],'fontsize',5,'color','r');
        a2 = a2 + b2;
        if ~rem(j,framesy), a1 = a1 + b1; a2 = 0; end;
      end;      
    end;
    
    for j=0:framesx,
      plot(0.5+[0,framesy*b2],0.5+b1*j*[1,1],'b-');
    end;
    for j=0:framesy,
      plot(0.5+b2*j*[1,1],0.5+[0,framesx*b1],'b-');
    end;
    
    axis equal
    axis([0 framesy*b2+1, 0, framesx*b1+1])
    axis off
    hold off;    
  otherwise,
    jmerror('dimension=?');
end;
% ==============================================================================

%==============================================================================
