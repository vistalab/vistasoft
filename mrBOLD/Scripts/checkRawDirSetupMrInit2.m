function [n, doThese]=checkRawDirSetupMrInit2(subs,startDir,fid)
% checkRawDirSetupMrInit2
%
% This will create a list of subjects (DOTHESE) to be preprocessed, listing
% only subjects with the proper Raw directory structure and no mrSESSION
% file (haven't already been preprocessed). 
%
% This should return two output arguments
% (1) n = number of subjects that are suitable for further preprocessing
% (2) doThese = list of subject directories that should be operated on
%
% By AL & DY, 09/08/2008

doThese=[];
anatDir='Anatomy';
pfilesDir='Pfiles';
inplaneDir='Inplane';

%Check through each subject's directory
for ii=1:length(subs)
    fprintf(fid,'\n ------------------------------------------ \n');
    fprintf(fid,'Checking Raw directory for %s\n\n',fullfile(startDir,subs{ii}));
    fprintf('Checking Raw directory for %s\n\n',fullfile(startDir,subs{ii}));
   %check for Raw directory and continue if doesnt exist, set flag
    thisDir=fullfile(startDir, subs{ii}, 'Raw');
    theanatDir=fullfile(thisDir,anatDir);
    theinplaneDir=fullfile(thisDir,anatDir,inplaneDir);
    thepfilesDir=fullfile(thisDir,pfilesDir); 
    
    go1=checkIfDir(fid,thisDir);
    go2=checkIfDir(fid,theanatDir);
    go3=checkIfDir(fid,theinplaneDir);
    go4=checkIfDir(fid,thepfilesDir);
    
    % If all their directories are correct and they haven't already been
    % initialized (no mrSESSION), consider them fair game for preprocessing
    if (go1==1 && go2==1 && go3==1 && go4==1 && ~exist(fullfile(mrvDirup(thisDir),'mrSESSION.mat'),'file'))
        fprintf('\nPROCEED: Subject %s does not have a mrSESSION.mat file', thisDir);
        fprintf(fid,'\nPROCEED: Subject %s does not have a mrSESSION.mat file', thisDir);
        doThese=[doThese subs(ii)];
    else
        fprintf('\nERROR: Subject %s is not suitable for preprocessing', thisDir);
        fprintf(fid,'\nERROR: Subject %s is not suitable for preprocessing', thisDir);
    end
    doThese
end
n=length(doThese);

return

%%%%%%
function go=checkIfDir(fid,thedir);

if ~isdir(thedir)
    fprintf('\nERROR: Subject''s %s directory is not set up correctly', thedir);
    fprintf(fid,'\nERROR: Subject''s %s directory is not set up correctly', thedir);
    go=0
else
    fprintf('\nPROCEED: Subject''s %s directory is set up correctly', thedir);
    fprintf(fid,'\nPROCEED: Subject''s %s directory is set up correctly', thedir);
    go=1
end
return