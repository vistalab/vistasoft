function idx = fignum2VIEWindex(figNum)
%
%  idx = fignum2VIEWindex(figNum)
%
% Author: Wandell
% Purpose:
%    Each figure shows some object (INPLANE,FLAT, or VOLUME), but we don't
%    always know which object goes with window, say, 2.  Use this routine
%    to figure out the correspondence.
%
%    If you know FLAT{ii}, then the figNum is stored in FLAT{ii}.ui.figNum.
%    This should be handled by viewGet(view,'fignum') some day.
%     
%    idx = fignum2VIEWindex(2)
%
mrGlobals;

idx = [];

for idx=1:length(INPLANE)
    if ~isempty(INPLANE{idx}) & checkfields(INPLANE{idx},'ui')
        if (figNum == INPLANE{idx}.ui.figNum)
            return;
        end
    end
end

for idx=1:length(VOLUME)
    if ~isempty(VOLUME{idx}) & checkfields(VOLUME{idx},'ui')
        if (figNum == VOLUME{idx}.ui.figNum)
            return;
        end
    end
end

for idx=1:length(FLAT)
    if ~isempty(FLAT{idx}) & checkfields(FLAT{idx},'ui')
        if (figNum == FLAT{idx}.ui.figNum)
            return;
        end
    end
end

return;
