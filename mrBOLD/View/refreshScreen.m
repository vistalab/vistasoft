function vw = refreshScreen(vw,varargin)
%
% vw = refreshScreen(vw,[optional args])
%
% Calls vw.refreshFn to refresh the window with optional arguments.
%
% djh, 8/98
%

% Programming notes
% BW -- This needs to be re-written or go away.  Should use varargin.  Not
% entirely clear why we need this on top of refreshView.
% RAS -- The new views I've made (inplane montage, 3-way views, etc)
% use refresh functions other than 'refreshView'. So refreshScreen
% is a little nicer than refreshView. I've cleaned up the optional
% input args, not sure if anyone actually uses those, but it's good
% to have around.
% ras 12/06: attempted rewrite to simplify things:
% we evaluate the view refresh function without reference to globals or 
% the base workspace, as Alex suggests. 
if ~exist('vw', 'var') || isempty(vw)
    vw = getCurView;
end

if ~isfield(vw, 'refreshFn') || isempty(vw.refreshFn), return; end

if isempty(varargin)
	vw = feval(vw.refreshFn, vw);
    
elseif length(varargin)==1
    vw = feval(vw.refreshFn, vw, varargin{1});
    
elseif length(varargin)==2 
    % generalize if we ever need >2 args (I thought 1 was enough a month
    % ago!)
    vw = feval(vw.refreshFn, vw, varargin{1}, varargin{2});
    
end
   

return