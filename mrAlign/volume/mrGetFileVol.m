function [estr] = mrGetFileVol(command,prom,args)
%function [estr] = mrGetFileVol(command,prom,args)
%
% mrGetFileVol
%
%	estr = mrGetFileVol(command,prom,args)
%
%	Prompts for file name, adds "vol" suffix to it and inserts
%	command argument at beginning of executable string that is returned.
%

foo = input(prom,'s');
if (nargin == 2)
	estr = [command,' ',foo,'vol'];
end
if (nargin == 3)
	estr = [command,' ',foo,'vol',' ',args];
end

return

