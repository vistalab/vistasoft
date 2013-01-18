function index = getNewViewIndex(view)
% Find the index in a view cell array to which to add a new view.
%
% index = getNewViewIndex(view);
%
% ARW, sometime around 2002.
% RAS, updated in 2007: checks if there's an empty entry in 
% the view cell array (e.g. from closing a window) and re-uses that.
% E.g., if VOLUME = {[struct] [] [struct]}, the new index should be
% 2 (fill in the empty slot), instead of 4 (add another slot).
index = 1;
while (index <= length(view)) &  (~isempty(view{index}))
	index = index + 1;
end
return
