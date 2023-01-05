% JM: 2006/07/19
% viewer for data Tc on domain Omega 


function varargout = viewImage(varargin);
% this is just output and hence not commented; fell free to improve (-;
% function varargout = viewImage(Tc,Omega,m,varargin);

persistent PARA 
% -----------------------------------------------------------------------------
if nargin == 0,  
  varargout{1} = PARA;
  return;
end;
% set persistent parameter
if nargin >= 1 & strcmp(varargin{1},'set'),
  
  if strcmp(varargin{2},'para'),
    viewPara = varargin{3};
    fn = fieldnames(viewPara);
    for j=1:length(fn),
      para{2*j-1} = fn{j};
      para{2*j}   = getfield(viewPara,fn{j});
    end;
    viewImage('set',para{:})
    return;
  end;
  
  % default parameter
  fprintf('%s: set persistent parameter\n',mfilename)
  PARA.viewer   = [];
  PARA.figname  = [];
  PARA.fig      = 1;
  PARA.sub      = [1,1,1];
  PARA.name     = '';
  PARA.plots    = 1;
  PARA.scale    = 0;
  PARA.invert   = 0;
  
  varargin(1) = [];
  % overwrite default parameter 
  for j=1:length(varargin)/2,
    field = varargin{2*j-1};
    value = varargin{2*j};
    PARA  = setfield(PARA,field,value);
  end;
  if nargout > 0, varargout{1} = PARA;  end;
  return;
end;
% -----------------------------------------------------------------------------


% -----------------------------------------------------------------------------
% start to work


Tc    = varargin{1};
Omega = varargin{2};
m     = varargin{3};
varargin(1:3) = [];

% start with global parameters and update
para = PARA;
for j=1:length(varargin)/2,
  field = varargin{2*j-1};
  value = varargin{2*j};
  para  = setfield(para,field,value);
end;


if ~para.plots, return;  end;          % do nothing, just return;

% build parameter list
fields = fieldnames(para);
for j=1:length(fields);
  optn{2*j-1} = fields{j};
  optn{2*j}   = getfield(para,fields{j});
end;

if isfield(para,'scale') & para.scale,
  Tc = 255/max(Tc)*Tc;
end;

if isfield(para,'invert') & para.invert,
  Tc = max(Tc)-Tc;
end;

% setup figure

fig = figure(para.fig);
subplot(para.sub(1),para.sub(2),para.sub(3)); cla;

if ~isempty(para.figname),
  set(fig,'numbertitle','off','name',sprintf('[JM-%d]: %s',fig,para.figname));
end;

% call the viewer

fh = feval(para.viewer,Tc,Omega,m,optn{:});

str = sprintf('%s',para.name);
title(str);

if nargout>0,
  varargout{1} = fh;
end;

return;
% 
% if nargout>0,  varargout{1} = fh;  end;
% return;
% %==============================================================================
% 
% 
% function p = volview(I,Omega,m,varargin)
% 
% I = reshape(I,m);
% % I = flipdim(I,3);
% isovalue    = 0;
% viewpoint   = [-37.5,30];
% facecolor   = .75*[1,1,1];
% facealpha   = .8;
% 
% %% overwrite default parameter 
% for k=1:1:length(varargin)/2,
%   %disp([varargin{2*k-1},'=varargin{',int2str(2*k),'};']);
%   eval([varargin{2*k-1},'=varargin{',int2str(2*k),'};']);
% end;
% 
% I(I<isovalue) = 0;
% 
% p(1) = patch(isosurface(I,isovalue));
% 
% switch computer,
% case 'PCWIN',
%   set(p(1),...
%     'FaceColor',facecolor,...
%     'EdgeColor','none');
% otherwise,
%   set(p(1),...
%     'FaceColor',facecolor,...
%     'EdgeColor','none',...
%     'FaceAlpha',facealpha);
% end;
% 
% isonormals(I,p(1))
% 
% p(2) = patch(isocaps(I,isovalue));
% 
% set(p(2),...
%   'FaceColor','interp',...
%   'EdgeColor','none');
% 
% view(viewpoint); 
% axis equal
% axis([1,size(I,2),1,size(I,1),1,size(I,3)]);
% camlight; lighting phong
% material dull
% drawnow
% %==============================================================================
% 
% %==============================================================================
% function ih = montage(I,Omega,m,varargin)
% 
% I = reshape(I,m);
% 
% threshold = 0;
% framesx   = [];
% framesy   = [];
% direction = 'x';
% number    = 'off';
% colmap    = [];
% %% overwrite default parameter 
% for k=1:1:length(varargin)/2,
%   %disp([varargin{2*k-1},'=varargin{',int2str(2*k),'};']);
%   eval([varargin{2*k-1},'=varargin{',int2str(2*k),'};']);
% end;
% 
% if threshold ~= 0,
%   I(I<threshold) = 0;
% end;
% 
% I = squeeze(I);
% l = length(size(I));
% 
% fig = gcf;
% switch l,
%   case 1,
%     hh = plot(1:size(I,1),I);
%   case 2,
%     hh = subimage(I,colmap);
%     if ~isempty(colmap), colormap(colmap); end;
%   case 3,
%     [m1,m2,m3] = size(I); 
%     
%     switch direction,
%       case 'x',
%         aa = m1; b1 = m2; b2 = m3; I1 = 1:m2; I2 = 1:m3;
%       case 'y',
%         aa = m2; b1 = m1; b2 = m3; I1 = 1:m1; I2 = 1:m3;
%       case 'z',
%         aa = m3; b1 = m1; b2 = m2; I1 = 1:m1; I2 = 1:m2;
%         
%       otherwise, jmerror(direction);
%     end;
%     
%     if isempty(framesx) & isempty(framesy),
%       framesx = ceil(sqrt(aa));  
%       framesy = ceil(aa/framesx);
%     elseif isempty(framesx),
%       framesx = ceil(aa/framesy);
%     else
%       framesy = ceil(aa/framesx);
%     end;
%     
%     %   fprintf('image is %dx%dx%d, frames [%d,%d]\n',...
%     %     m1,m2,m3,framesx,framesy);
%     
%     B = zeros(b1*framesx,b2*framesy);
%     
%     a1 = 0; a2 = 0;
%     for j=1:aa,      
%       switch direction,
%         case 'x',  P = squeeze(I(j,:,:));
%         case 'y',  P = squeeze(I(:,j,:));
%         case 'z',  P = squeeze(I(:,:,j));
%       end;      
%       B(a1+I1,a2+I2) = P;
%       a2 = a2 + b2;
%       if ~rem(j,framesy), a1 = a1 + b1; a2 = 0; end;
%     end;
%     
%     ih = image(B);
%     if ~isempty(colmap), colormap(colmap); end;
%     hold on
%     
%     if strcmp(number,'on'),
%       a1 = 0; a2 = 0;
%       for j=1:aa,
%         text(a2+10,a1+20,['#',int2str(j)],'fontsize',5,'color','r');
%         a2 = a2 + b2;
%         if ~rem(j,framesy), a1 = a1 + b1; a2 = 0; end;
%       end;      
%     end;
%     
%     for j=0:framesx,
%       plot(0.5+[0,framesy*b2],0.5+b1*j*[1,1],'b-');
%     end;
%     for j=0:framesy,
%       plot(0.5+b2*j*[1,1],0.5+[0,framesx*b1],'b-');
%     end;
%     
%     axis equal
%     axis([0 framesy*b2+1, 0, framesx*b1+1])
%     axis off
%     hold off;    
%   otherwise,
%     jmerror('dimension=?');
% end;
% % ==============================================================================
% 
% %==============================================================================
function  PARA = setPARA(varargin)
%fprintf('%s\n',mfilename)
PARA = [];

% overwrite default parameter
for k=1:1:length(varargin)/2,
  field = varargin{2*k-1};
  value = varargin{2*k};
  PARA = setfield(PARA,field,value);
end;

