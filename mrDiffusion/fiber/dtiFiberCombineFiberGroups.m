function fg = dtiFiberCombineFiberGroups(fgList,outName,type)
% 
% fg = dtiFiberCombineGroups([fgList=uiselectfile],...
%                            [outName='combinedFiberGroup'],[type='pdb'])
% 
% Combine N fiber groups (pdb or mat) into a single fiber group and save.
% This routine is a wrapper for dtiMergeFiberGroups, making it simple to
% comine an arbitrary number of groups. 
% 
% INPUTS:
%   fgList  - CELL ARRAY of fiber names. 
%   outName - Name of fiber group to save. 
%   type    - 'mat' or 'pdb'
%
% 
% (C) Stanford University, VISTA Lab 
% 

%% Check INPUTS

if notDefined('fgList') 
    [names p] = uigetfile({'*.pdb';'*.mat'}, 'Select fiber groups','MultiSelect','on');
    for ff=1:numel(names)
        fgList{ff} = fullfile(p, names{ff});
    end
end

if ~iscell(fgList)
    error('fgList must be a cell array of fiber names'); 
end

if notDefined('type')
    type = 'pdb';
end

if notDefined('outName')
        outName = fullfile(pwd,['combinedFiberGroup.' type]);
        name = 'combinedFiberGroup';
else
    [~, name ~] = fileparts(outName);
end
    

%% Combine the fiber groups

disp('Combining fiber groups...');

for ii=1:numel(fgList)
    if ii==1
        fg = fgRead(fgList{ii});
    else
        fgM = fgRead(fgList{ii});
        fg = dtiMergeFiberGroups(fg,fgM);
    end
    
end

fg.name = name;


%% Save

fprintf('\n Saved: %s\n', outName);
fgWrite(fg,outName,type);
    

return
    