function dtiMergeSuperFiberGroups(SuperFiberGroupsListFile,SuperFibersGroupsAllFileName)

% Append together SuperFibersGroup from SuperFiberGroupsList (a txt file with filenames in rows) into one dataset SuperFibersGroupsAll.

% ER 02/2008 SCSNL

%The new file contains the following variables:
%SuperFiberGroupsList
%coordinateSpace 
%versionNum
%fg.n
%fg.fibers
%fg.fibervarcovs

count=0;
fid=fopen(SuperFiberGroupsListFile, 'r');
while 1
    count=count+1;
    tline=fgetl(fid);
    if ~ischar(tline)
        break
    end
       
SuperFiberGroupsList(count)=cellstr(tline);
end
fclose(fid);


load(char(SuperFiberGroupsList(1))); 
mergedFG=fg; 
mergedcoordinateSpace=coordinateSpace; 
mergedversionNum=versionNum;

for SFGID=2:length(SuperFiberGroupsList)
[PATHSTR,NAME,EXT,VERSN] = fileparts(char(SuperFiberGroupsList(SFGID)));
    load(NAME); 
if strcmp(coordinateSpace, mergedcoordinateSpace) & versionNum==mergedversionNum
mergedFG.fibers=vertcat(mergedFG.fibers, fg.fibers);
mergedFG.fibervarcovs=vertcat(mergedFG.fibervarcovs, fg.fibervarcovs);


mergedFG.n=vertcat(mergedFG.n, fg.n);

else
    display(['Incompatible coordinate space or mrDiffusion version number for '  char(SuperFiberGroupsList(SFGID))]); 
end
end

mergedFG.name='Appended SFGs -- see SuperFiberGroupsList'; 
fg=mergedFG;
save(SuperFibersGroupsAllFileName, 'fg', 'versionNum', 'coordinateSpace', 'SuperFiberGroupsList');