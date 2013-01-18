function selected = atlasSelectAtlas
%
%     selected = atlasSelectAtlas
%
% Author: BW, AAB,
% Purpose:
%    List dialogue to let the user select from the existing atlases (if selected >=1) 
%    indicate the user wants a new atlas (selected == 0) 
%    or the user decided to cancel, selected = [].
%

global dataTYPES;

atlasTypeNum = existDataType('Atlases',[],0);
str{1} = 'New Atlas';
if all(atlasTypeNum > 0)   % only if we have at least one atlas
	for ii=2:(length(atlasTypeNum)+1);
        str{ii} = dataTYPES(atlasTypeNum(ii-1)).name;
    end
end

[s,valid] = listdlg('PromptString','Select an Atlas:',...
    'SelectionMode','single',...
    'ListString',str);

% 
if valid
    s = s - 1;
    if s > 0,  selected = atlasTypeNum(s);
    else       selected = 0;
    end
else
    selected = [];
end

return;

