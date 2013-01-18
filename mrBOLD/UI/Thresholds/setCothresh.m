function view = setCothresh(view, value)
%
% view = setCothresh(view, value)
%
% Sets cothreshSlider value
% ras 01/07 -- update for hidden views.
if ~exist('view', 'var') | isempty(view), view = getCurView; end

if ~checkfields(view, 'ui', 'cothresh') | ~isstruct(view.ui.cothresh)
    view.settings.cothresh = value;
    
else    % slider structure
    setSlider(view,view.ui.cothresh,value);
    
end

return

