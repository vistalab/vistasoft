function updateGlobal(view)
% Sets the global value of a mrVista view to be the same 
% as the passed value.
%
% updateGlobal(view);
%
%
% This addresses a particular, really annoying side effect of the use of
% globals in mrVista. Views are stored in a global variable (such as
% INPLANE or VOLUME), but get passed into functions where they're local
% copies ('view'), and are modified. These modifications don't always make
% it back to the base workspace, so views update erratically.
%
% For instance, if you always call a function of the form INPLANE{1} =
% computeMeanMap(INPLANE{1}, 1), the global INPLANE will be updated. But if
% you evaluate computeMeanMap(INPLANE{1}, 1), it won't. Also, since some
% functions don't return a view per se (e.g., code which returns a time
% course detrended by information in the view), changes to the view end up
% happening again and again.
%
% This code basically puts the contents of the local 'view' structure into
% the global variable of the same name, so you can update the variable
% without calling, e.g. refreshScreen.
%
% ras, 02/2007.
assignin('base', 'TMP', view);
evalin('base', sprintf('%s = TMP;', view.name));
evalin('base', 'clear TMP');
return
