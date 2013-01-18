function atlasTypeNum = atlasSelect
%
%  atlasTypeNum = atlasSelect
%
% Author: Wandell, Brewer
% Purpose:
%    Select a single atlas from one of a set of possible atlases.  If no
%    atlases are present an error is created.
%

warning('May be obsolete.  Perhaps you want to use atlasSelectAtlas?  Or maybe not.')

atlasTypeNum = existDataType('Atlases',[],0);
if(atlasTypeNum == 0)
    myErrDlg('No Atlases data type!');
elseif length(atlasTypeNum) > 1
    prompt = {'Select Atlas Number'};
    default = {num2str(atlasTypeNum)};
    answer = inputdlg(prompt, 'Choose the atlas', 1, default, 'on');
    if isempty(answer); return; else atlasTypeNum = str2num(answer{1}); end
end

return;
