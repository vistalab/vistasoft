% function [ML,minLevel,maxLevel] = getMultiLevel(TD,RD,Omega,m,varargin)
%
% (c) JM, NP; SAFIR, Luebeck, 2006
%
% input:
%   - TD, RD    : the image data
%   - Omega, m  : the image domain and the size of the finest grid
%   - varargin  : our usual varargin construct (see documentation)
%       (changeable are 
%           plots   -   (0,1)   - graphical output, yes or no
%           fig     -           - number of figure for graphical output
%           dopause -   (0,1)   - make a break after computing on level
%           minLevel-           - the size of the coarest grid (so the
%           gridsize is 2^minLevel)
%
% output:
%   - ML      : a cell array storing the MultiLevel information
%         ML.RD, ML.TD, ML.Omega, ML.m 
%         ML{minLevel:1:maxLevel} holds the data
%   - maxLevel: Maximum grid size (2^maxLevel is the gridsize)
%   - minLevel: Minimum grid size
%

function [ML,minLevel,maxLevel] = getMultiLevel(TD,Omega,m,varargin);

% set some default values to the variables that can be set by
% the varargin-construct
plots    = 1;
fig      = 2;
dopause  = 0;
minLevel = 3;
titlestr = '';
noL      = [];

% read the variables from varargin
for k=1:1:length(varargin)/2,
  eval([varargin{2*k-1},'=varargin{',int2str(2*k),'};']);
end;
dim = length(Omega);

% print out the variables that have been set
fprintf('%s(plots=%d,dim=%d)\n',mfilename,plots,dim);

% get a standard grid an the representation of RD and TD on this grid for
% visualization and to have the data on a grid which size is a power of 2
[X,h,n]   = getGrid(Omega,m);
Tc = interpolation(TD,Omega,X);

% get the maxlevel
maxLevel = ceil(log2(min(m)));
if ~isempty(noL)
  minLevel = maxLevel - noL + 1;
end;

figs     = zeros(maxLevel);

% want some plots?
if plots,
  fig = figure(fig); clf;
  str = sprintf('[FLIRT-%d]: %s: create multilevel for %dD-date, levels range from %d to %d',...
    fig,mfilename,length(m),maxLevel,minLevel);
  set(fig,'numbertitle','off','name',str);
end;

% some output to the console
fprintf('%s: create multilevel data [',mfilename);

% start the loop from maxlevel to minlevel
for level = maxLevel:-1:minLevel
  if level == maxLevel,
    % n = number of pixels (whereever it is needed :-) ) 
    n = prod(m);
    % put the images into matlab's matrix representation
    switch dim
      case 2
        Tp = flipud(reshape(Tc,m)');
      case 3
        J = permute(reshape(1:n,m(2),m(1),m(3)),[2,1,3]);
        Tp = reshape(Tc(J(:)),m(1),m(2),m(3));
    end;
    mp = m;
    fprintf(' %d',level);
  else
    % now restrict the information of the image data to the
    % next coarser grid; we use a simple mean-operator
    L = ML{level+1};   
    Tp = L.D;
    Tp = 0.5*(Tp(1:2:end,:,:) + Tp(2:2:end,:,:));
    Tp = 0.5*(Tp(:,1:2:end,:) + Tp(:,2:2:end,:));        

    % for 3D an extra step in the third dimension has to be done
    if dim == 3,      
      Tp = 0.5*(Tp(:,:,1:2:end) + Tp(:,:,2:2:end));        
    end;
    
    % shrink the image dimension
    mp = L.m/2;
    fprintf(' %d',level);
  end;

  % save the data for the current level in a struct
  % and put it in a cell array for output
  L.D      = Tp;
  L.Omega  = Omega;
  L.m      = mp;
  
  ML{level} = L;
  
  
  % if some plots are needed visualize the represenstion of the data
  % on the current level
  if plots,
    [X,h,n] = getGrid(Omega,mp);
    Tc = interpolation(Tp,Omega,X);

    Rstr = sprintf('%dx%d',mp);
    

    s1 = [1,maxLevel-minLevel+1,level-minLevel+1];
    Tstr = sprintf('%s, %s',titlestr, dimstr(mp));
    
    viewImage(Tc,Omega,mp,'name',Tstr,'fig',fig,'sub',s1);
    
    if dopause, 
      pause
    else
      drawnow
    end;
  end;  
  
end;

fprintf('] done\n');
if dopause, pause; end;
return;

%==============================================================================
% function str = dimstr(value)
% just put a vector in its string representation for easier ouput on the
% matlab console
function str = dimstr(value)
str = sprintf('%s = [%s',inputname(1),num2str(value(1)));
for j=2:length(value),
  str = [str,sprintf(',%s',num2str(value(j)))];
end;
str = sprintf('%s]',str);
return
%==============================================================================
