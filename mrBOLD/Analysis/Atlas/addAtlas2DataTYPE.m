function [atlasName, newTypeNum] = addAtlas2DataTYPE
%
%  [atlasName, newTypeNum] = addAtlas2DataTYPE
%
% Author: Wandell
% Purpose:
%    Use an input dialog to obtain a new Atlas name and create the new
%    dataTYPE entry.
%
%    atlasName is the atlas name
%    newTypeNum is the index into dataTYPES where the new atlas is added.

global dataTYPES;

atlasTypeNum = existDataType('Atlases',[],0);

if atlasTypeNum ~= 0
    str = sprintf('%s ',dataTYPES(atlasTypeNum(:)).name);
    tmpAtlasName = sprintf('Atlases-%.0f',length(atlasTypeNum)+1);
else
    str = 'None';
    tmpAtlasName = 'Atlases-1';
end

prompt={sprintf('Current atlas names: %s',str)};
dlgTitle='Input atlas name';
lineNo=1;
def{1} = tmpAtlasName;
atlasName = inputdlg(prompt,dlgTitle,lineNo,def);
atlasName = char(atlasName);

if isempty(atlasName)
    return;
elseif existDataType(atlasName)
    atlasName = [];
    warndlg(sprintf('Atlas %s exists.  Please switch to that data type in the window.',atlasName));
    return;
else
    newTypeNum = addDataType(atlasName); 
end

return;
