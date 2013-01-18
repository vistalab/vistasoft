function fileName = figCleanAndSave(figNum, fileName)
%
% fileName = figCleanAndSave(figNum, [fileName])
%

if(~exist('fileName','var') | isempty(fileName))
    [f,p] = uiputfile({'*.png','PNG (for screen)';'*.eps','EPS (for print)'},...
                        sprintf('Save Figure %d as...',figNum));
    if(isnumeric(f))
        disp('User Canceled.'); return;
    end
    fileName = fullfile(p,f);
end


fontName = 'Helvetica';
fontSize = 18;
%lineSize = 3;
dpi = 120;

[p,f,ext] = fileparts(fileName);
if(isempty(ext)) ext = 'png'; end

set(figNum, 'PaperPositionMode', 'auto');
switch(ext)
    case {'png','.png'},
        type = '-dpng';
        res = ['-r' num2str(dpi)];
    case {'eps','.eps'},
        type = '-depsc';
        res = '';
    otherwise
        error('unrecognized file extension');
end

figChildren = get(figNum,'Children');
for(ii=1:length(figChildren))
    set(figChildren(ii), 'fontName', fontName, 'fontSize', fontSize);
    set(get(figChildren(ii),'XLabel'), 'fontName', fontName, 'fontSize', fontSize);
    set(get(figChildren(ii),'YLabel'), 'fontName', fontName, 'fontSize', fontSize);
    set(get(figChildren(ii),'Title'), 'fontName', fontName, 'fontSize', fontSize);
end


if(~isempty(res))
    print(figNum, type, res, fileName);
else
    print(figNum, type, fileName);
end

return
