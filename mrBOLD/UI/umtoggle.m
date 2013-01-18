function newState = umtoggle(h);
% UMTOGGLE: toggle the 'Checked' property of a uimenu, returning the
% new state as a 0 or 1. Local mrVista version.
%
%  newState = umtoggle([uimenu handle or label text]);
% 
% Had to write a function for this, because Mathworks inexplicably 
% made its (perfectly good) built-in UMTOGGLE function obsolete for
% matlab versions r2006b and later. 
% 
% This code behaves exactly the same way, only it doesn't complain to 
% you about the obsolete status. While I was at it, I also allow the
% input argument to be the label text for a menu, in which case, it
% will toggle the first menu found with that label.
%
% ras, 06/2007.
if nargin<1
	error('Need an input argument.')
end

% check if we have a menu label
if ischar(h)
	menus = findobj('Type', 'uimenu', 'Label', h);
	
	if isempty(menus)
		error(sprintf('Menu with label %s not found.', h));
	end
	h = menus(1);
end 

checked = get(h, 'Checked');

if isequal(checked, 'on')
	newState = 0;  set(h, 'Checked', 'off');
else
	newState = 1;  set(h, 'Checked', 'on');
end

return


