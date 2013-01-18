function cothresh = getCothresh(vw)
%
% cothresh = getCothresh(<vw=current vw>)
%
% Gets cothresh value from cothreshSlider (non-hidden view),
% or else from vw.settings.cothresh field (hidden view).
% If it can't find either, defaults to 0.10.
%
% ras 06/06.
%
% jw, 6/2010: Obsolete. Use cothresh = viewGet(vw, 'cothresh') instead

if nargin<1, vw = getCurView; end

cothresh = viewGet(vw, 'cothresh');

warning('vistasoft:obsoleteFunction', 'getCothresh.m is obsolete.\nUsing\n\tcothresh = viewGet(vw, ''cothresh'')\ninstead.');

% if ~isequal(vw.name,'hidden')
%     cothresh = get(vw.ui.cothresh.sliderHandle,'Value');
% else
%     if checkfields(vw, 'settings', 'cothresh')
%         cothresh = vw.settings.cothresh;
%     else
%         % arbitrary val for hidden views
%         cothresh = 0.20;
%     end
% end
% 
% return
%     
