fmriBaseDir = 'Y:\data\reading_longitude\fmri\';
dtiBaseDir = 'Y:\data\reading_longitude\dti_y2\';
subDir = {'rs0','sg','sy0','tv',...
'cp','crb','ctb','ctr','da','dh','dm','hy','js','jt','kj','ks',...
     'lg','lj','mb','md','mh0','mho','mm','pf','rh',
    'vh','vr'}; % put in a list of subjects who have the func rois. make sure they are all named in the same way
roiName = {'LOTS','ROTS'};

for(ii=1:length(subDir))
    fmriworkDir = [fmriBaseDir subDir{ii} '*PhaseW*'];
    d = dir(fmriworkDir);
    fmriworkDir = [fmriBaseDir d.name];
    chdir(fmri
    workDir);
    volumeWin = initHiddenVolume();
    volumeWin = loadROI(volumeWin,roiName{1});
    volumeWin = loadROI(volumeWin,roiName{2});
    
    %load dt6 for this subject in dti dir
    dtiWorkDir = [dtiBaseDir subDir{ii} '*'];
    d = dir(dtiWorkDir);
    dtiWorkDir = [dtiBaseDir d.name];

    dt6fname = fullfile(dtiWorkDir, [d.name '_dt6.mat']);
    disp(['Processing ' dt6fname '...']);
    
    if ~exist(fullfile(fileparts(dt6fname), 'ROIs','OTSproject'),'dir')
        roiPath = fullfile(fileparts(dt6fname), 'ROIs','OTSproject');
        mkdir(fullfile(fileparts(dt6fname), 'ROIs','OTSproject'));
        dt = load(dt6fname);
        if(~isfield(dt,'xformToMrVista'))
            load('mrSESSION');
            if(~isempty(mrSESSION) & isfield(mrSESSION,'subject'))
                vAnatFile = fullfile(getAnatomyPath(lower(mrSESSION.subject)),d.name,'t1','vAnatomy.dat');
                %vAnatFile = fullfile(getAnatomyPath(lower(mrSESSION.subject)),'vAnatomy.dat');
            else
                vAnatFile = '';
            end
            if(isempty(vAnatFile) | ~exist(vAnatFile, 'file'))
                [f,p] = uigetfile({'*.dat','vAnatomy files (*.dat)'; '*.*','All Files (*.*)'},'Select vAnatomy file for this subject');
                if(isnumeric(f)) error('user canceled.'); end
                vAnatFile = fullfile(p,f);
            end
            [vAnatomy,vAnatMm] = readVolAnat(vAnatFile);
            [p,f,e] = fileparts(vAnatFile);
            talFile = fullfile(p,[f '_talairach.mat']);
            vAnatTal = loadTalairachXform('', talFile);
            xformToMrVista = dtiXformVanatCompute(dt.anat.img, dt.anat.xformToAcPc, vAnatomy, vAnatMm, vAnatTal);
            save(dt6fname, 'xformToMrVista', '-APPEND');
            dt.xformToMrVista = xformToMrVista;
        end
        %compute mrVista xform
        %import mlr ROIs
        for(roiNum=1:length(volumeWin.ROIs))
            mrVistaRoi = volumeWin.ROIs(roiNum);
            % Transform mrVista coords to dti ac-pc space
            coords = mrAnatXformCoords(dt.anat.xformToAcPc * dt.xformToMrVista, mrVistaRoi.coords);
            coords = unique(round(coords),'rows');
            roi = dtiNewRoi(mrVistaRoi.name, mrVistaRoi.color, coords);
            dtiWriteRoi(roi, fullfile(fileparts(dt6fname),'ROIs','OTSproject',[roi.name '.mat']));
            %save ROIs in dti dir \ROIs\OTSproject
        end
    end
    clear GLOBAL mrSESSION;
end
