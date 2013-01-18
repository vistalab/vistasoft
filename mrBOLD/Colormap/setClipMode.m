function vw = setClipMode(vw,field,mode)
% vw = setClipMode(vw,[field,mode]);
%
% Set the clip mode of a given field ('amp', 'map', etc) for the 
% view.
%
% ras 05/30/04.
if ~isfield(vw,'ui')  % hidden view
    fprintf('Erm ... this is a hidden view w/o a user interface.\n')
    return
end

ui = viewGet(vw,'ui');

if ieNotDefined('field')
    field = ui.displayMode;
end

fieldStr = sprintf('%sMode',field);

if ieNotDefined('mode')
    % get it from the user
    ttltxt = sprintf('Enter clip mode for %s view: ',field);
    def = {num2str(ui.(fieldStr).clipMode)};
    answer = inputdlg('[min max] (or, 0 or ''auto'' for auto mode):',ttltxt,1,def);
    vals = str2num(answer{1}); %#ok<ST2NM>
    if isempty(vals) || (length(vals)==1 && vals(1)==0) 
        mode = 'auto';
    else
        mode = vals(1:2);
    end
end

if isnumeric(mode)  % clip range has been specified
    ui.(fieldStr).clipMode = mode(1:2);
else
    % string passed -- assume 'auto'
    ui.(fieldStr).clipMode = 'auto';
end

vw = viewSet(vw,fieldStr,ui.(fieldStr));

refreshScreen(vw);

return