function dti_MT_xformMrVistaVolROIs

% This script will transform specified ROIs defined on the mrVista
% volume to mrDiffusion and save them. It calls the function
% dtiXformMrVistaVolROIs to do this. Inspired by 
% dti_FFA_xformMrVistaVolROIs.m.
%
% History:
% 12/3/08 LMP Wrote it

baseDir = '/biac3/wandell4/data/reading_longitude/';
fmriDir = fullfile(baseDir,'fmri');
vAnatDir = fullfile(baseDir,'dti_y1_old');
dtiYr = {'dti_y1','dti_y2','dti_y3','dti_y4'};
dt = 'dti06';
ROIs = {'LMT.mat','RMT.mat'};
% subs = {'ao0','am0','bg0','crb0','ctb0','da0','es0','hy0','js0','jt0','kj0','ks0',...
%             'lg0','lj0','mb0','md0','mh0','mho0','mm0','nf0','pt0','rh0','rs0','sg0',...
%             'sl0','sy0','tk0','tv0','vh0','vr0'};

subs = {'mh0'};


%% Initialize a logfile to keep track of subjects and ROIs. 
dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
logFile = fullfile(baseDir,'MT_Project','logs',['MT_log_xFormMtRois_',dateAndTime,'.txt']);
fid = fopen(logFile, 'w');
fprintf(fid,'  \n  xForming MT ROIs for %d subjects: %s', length(subs), date); 
fprintf(fid,'\n************************************************ \n');
fprintf(fid,'Subs: \r');
fprintf(fid, '  %s,', subs{:});
fprintf(fid, '\nROIs: \r');
fprintf(fid, '  %s ', ROIs{:});
fprintf(fid,'\n************************************************ \n');

% Do the Work
for ii=1:length(subs)
    % Set Directories
    vSubDir = dir(fullfile(vAnatDir,[subs{ii} '*']));
    vAnatomy = fullfile(vAnatDir,vSubDir.name,'t1','vAnatomy.dat');

    fSubDir = dir(fullfile(fmriDir,[subs{ii} '*MotDisc*']));
    roiDir = fullfile(fmriDir,fSubDir.name,'Volume','ROIs');
    fprintf(fid,'\n------------------------------------------ \n');
    fprintf(fid, '%s:\rvAnatomy used for xForm:\r  %s', subs{ii},vAnatomy);
    fprintf(fid, '\nROIs being xFormed:'); 

    % Create the ROI list
    for jj=1:length(ROIs)
        roiList{jj} = fullfile(roiDir,ROIs{jj});
        fprintf(fid, '\n  %s\r',roiList{jj});
    end
    
    % Loop through for each year of data
    for kk=1:length(dtiYr)
        dSubDir = dir(fullfile(baseDir,dtiYr{kk},[subs{ii} '*']));
        if ~isempty(dSubDir) % If there is no data for dtiYr{kk}, skip.
            dSubDir = fullfile(baseDir,dtiYr{kk},dSubDir.name);
            dt6Dir = fullfile(dSubDir, dt);
            dt6File = fullfile(dt6Dir,'dt6.mat');
            if exist(dt6File)
                saveDir = fullfile(dt6Dir,'ROIs','MT');
                if(~isdir(saveDir)), mkdir(saveDir); end

                % Transform the ROIs for each sub for each year
                disp(sprintf(['\n**Now xForming mrVista ROIs for ' subs{ii} ' in '  dtiYr{kk} '...']));
                dtiXformMrVistaVolROIs(dt6File,roiList,vAnatomy,saveDir)
                fprintf(fid, 'xFormed MT ROIs for: %s %s: ROIs saved to: %s  \r', subs{ii}, dtiYr{kk}, saveDir);
            else
                disp(sprintf(['\n No dt6.mat!!! for ' subs{ii} ' in '  dtiYr{jj} '! Skipping.']));
                fprintf(fid,'\n No dt6.mat for %s in %s. Skipping!\n', subs{ii}, dtiYr{jj});
            end
        else
            disp(sprintf(['\n No data for ' subs{ii} ' in '  dtiYr{kk} '! Skipping.']));
            fprintf(fid,'\n** No data for %s in %s. Skipping. \n', subs{ii},dtiYr{kk});
        end
    end
end
fprintf(fid,'\n\n*******\n DONE!\n*******\n');
fclose(fid); % Close out the log file.
disp(sprintf('\n*******\n DONE!\n*******'));

