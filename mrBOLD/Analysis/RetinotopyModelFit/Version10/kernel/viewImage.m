% JM: 2006/07/19
% viewer for data Tc on domain Omega

function varargout = viewImage(varargin);
% this is just output and hence not commented; fell free to improve (-;
% function varargout = viewImage(Tc,Omega,m,varargin);

persistent PARA

if nargin == 0,
  varargout{1} = PARA;
  return;
end;

% set persistent parameter
if nargin >= 1 & strcmp(varargin{1},'set'),
  PARA = setPARA(PARA,varargin{2:end});
  varargout{1} = PARA;
  return;
end;

if isstr(varargin{1}) & strcmp(varargin{1},'clear'),
  PARA = [];
  return;
end;

if isempty(PARA),
  PARA = setPARA(PARA,'viewer','image2D','colmap',gray(256));
  varargout{1} = PARA;
  warning('!!! no PARA given yet, set viewer to image2D !!!')
end;

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

% scale image to [0,255]
if isfield(para,'scale')  & para.scale,
  maxTc = max(Tc);
  Tc = 255/(maxTc+(maxTc==0))*Tc;
end;

% invert image
if isfield(para,'invert') & para.invert,
  Tc = max(Tc)-Tc;
end;


% setup figure
if ~isfield(para,'fig'), para.fig = [];   end;
if isempty(para.fig),    para.fig = gcf;  end;

fig = figure(para.fig);
if any(para.sub ~= 1),
  subplot(para.sub(1),para.sub(2),para.sub(3)); cla;
end;

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
%==============================================================================
function PARA = setPARA(PARA,varargin);

% set default parameter
p.viewer   = [];
p.figname  = [];
p.fig      = [];
p.sub      = [1,1,1];
p.name     = '';
p.plots    = 1;
p.scale    = 0;
p.invert   = 0;

% get default values
fn = fieldnames(p);
for j=1:length(fn),
  default{2*j-1} = fn{j};
  default{2*j}   = getfield(p,fn{j});
end;

% get old values
if isempty(PARA),
  current = {};
else
  fn = fieldnames(PARA);
  for j=1:length(fn),
    current{2*j-1} = fn{j};
    current{2*j}   = getfield(PARA,fn{j});
  end;
end;

% get new values
if strcmp(varargin{1},'para') | strcmp(varargin{1},'PARA'),
  PARA = varargin{2};
  fn = fieldnames(PARA);
  for j=1:length(fn),
    new{2*j-1} = fn{j};
    new{2*j}   = getfield(PARA,fn{j});
  end;
else
  new = varargin;
end;


optn = {default{:},current{:},new{:}};

% rewrite default parameter
PARA = [];
for j=1:length(optn)/2,
  field = optn{2*j-1};
  value = optn{2*j};
  PARA  = setfield(PARA,field,value);
end;

fprintf('%s: set view parameter, viewer=%s\n',mfilename,PARA.viewer);
return;
% -----------------------------------------------------------------------------
