function idx = fignum2FLATindex(figNum)
%
%  idx = fignum2FLATindex(figNum)
%
% Author: Wandell
% Purpose:
%    Each FLAT figure shows some FLAT{} object, but we don't always know
%    which FLAT{} object goes with window, say, 2.  Use this routine to
%    figure out the correspondence.
%
%    If you know FLAT{ii}, then the figNum is stored in FLAT{ii}.ui.figNum 
%     
%    idx = fignum2FLATindex(2)
%
mrGlobals;

warning('Use fignum2VIEWindex instead.')

idx = [];

for idx=1:length(FLAT)
    if ~isempty(FLAT{idx})
        if (figNum == FLAT{idx}.ui.figNum)
            return;
        end
    end
end

return;
