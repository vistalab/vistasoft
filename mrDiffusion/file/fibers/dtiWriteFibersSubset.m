function outFgFile=dtiWriteFibersSubset(parentFgFile, indices, outFgFile, outFgName,  subgrouplabels, subgroupNames)
%  dtiWriteFiberGroupHandle(parentFgFile, indices, outFgFile, [outFgName],
%  [subgrouplabels], [subgroupNames])
% 
%  Given a fiber group, save a reference to this fiber groups (as a
%  "parent") and a list of indices forming a selection of choice.
%  outFileName in this format can be read by dtiReadFibers
% 
% 2009.05.29 ER wrote it 
% 2009.07.21 ER modified to properly handle fghandles in "parent" field.

if ~strcmp(fileparts(parentFgFile) , fileparts(outFgFile) )
error('Parent and subset files are located in different directories');
end

if(~exist('outFgName','var') || isempty(outFgName))
load(parentFgFile);
outFgName=[fg.name ' subset'];
end

fghandle.name=outFgName;
[parentPathstr, parentName, parentExt] = fileparts(parentFgFile) ;
fghandle.parent=[parentName parentExt];
fghandle.ids=indices;

exist('subgrouplabels', 'var')
if exist('subgrouplabels', 'var')
    fghandle.subgroup=subgrouplabels; 
end

if exist('subgroupNames', 'var')
    fghandle.subgroupNames=subgroupNames; 
end

save(outFgFile, 'fghandle');