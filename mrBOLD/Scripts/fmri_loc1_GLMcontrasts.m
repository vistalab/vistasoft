function fmri_loc1_GLMcontrasts

% LO Localizer scans processing code
%
% USER IMPORTANT!!!: Before running this script, make sure that all loloc
% scans have the correct annotation fields and scan groups (are grouped
% correctly). Otherwise, fmri_FFA_checkDataTypesForGLM will fail. 
%
% 1. Set GLM parameters for all scans
% 2. Check LO localizer experiments for:
%    a. Datatype and scan numbers
%    b. Record parfiles
%    c. Make sure scan groupings are correct
% 3. Run GLM for LO localizer experiments 
% 4. Run contrasts for the LO localizer experiments
%
% Calls the functions:
% * fmri_loc1_setGLMparams (subfunction)
% * fmri_loc1_checkDataTypesForGLM
% * fmri_loc1_computeContrastsLocalizer
%
%
% DY 06/05/2008
% Modified 06/18/2008: there are calls to er_setParams and saveSessions all
% over the place, which results in the params for the MotionComp_RefScan1
% being changed for the worse. I'm not sure how to efficiently prevent this
% from happening, so instead, I let it happen, and just fix the ANNOTATION
% and PARFILE fields at the end, since accuracy here is important. 
%
% Code taken from fmri_FFA_motionCompFix
% AL 11/08: Adapted for loc1 GLM

clear all 

% Set directory and subject list
% Alternatively: subs = {'sess1','sess2','sess3',...};
if ispc
    fmriDir = 'W:\projects\Kids\fmri\localizer\'; 
else
    %fmriDir = '/biac1/kgs/projects/Kids/fmri/localizer/';
    fmriDir='/biac1/kgs/projects/Kids/fmri/code/Alina/Subject/';
end
cd(fmriDir); s=dir('*0*'); subs={s.name}; 

% Start a log text file to document successes and failures in preprocessing
dateAndTime=datestr(now); dateAndTime(12)='_'; dateAndTime(15)='h';dateAndTime(18)='m';
logDir=fullfile(fmriDir,'logs');
if ~isdir(logDir), mkdir(logDir), end; 
logFile = fullfile(fmriDir,'logs',['LO1_Log_' dateAndTime '.txt']);
fid=fopen(logFile,'w');
[junk,logFileName]=fileparts(logFile)
scriptName = 'fmri_loc1_GLMcontrasts.m';
startTime = clock;

% 1. Set GLM parameters
params=fmri_loc1_setGLMparams(fid,logFileName,scriptName); % Subfunction within this script

for ii=1:length(subs)
    
    % Get rid of all mrVista globals in workspace. Put this at the top,
    % just in case we break from the rest of the loop. 
    clear dataTYPES mrSESSION vANATOMYPATH HOMEDIR hI newDt newScan

    thisDir = fullfile(fmriDir,subs{ii}); cd(thisDir);
    fprintf(fid,'\n ------------------------------------------ \n');
    fprintf(fid,'Processing %s\n\n',thisDir);
    fprintf('Processing %s\n\n',thisDir);

    %% Check if the subject already has been processed by script (and thus
    %% should not be re-entered to this script). If they do, skip to the
    %% next subject by using CONTINUE.
    load mrSESSION.mat
    theglm=find(strcmp({dataTYPES.name},'GLMs'));
    if ~isempty(theglm)
        checkScans=length(dataTYPES(theglm).eventAnalysisParams);
        alreadyDone=[];
        for xx=1:checkScans
            tmp=(strfind(lower(dataTYPES(theglm).eventAnalysisParams(xx).annotation),'lo localizer run 1'));
            alreadyDone=[alreadyDone tmp];
        end
        if(~isempty(alreadyDone))
            fprintf(fid,'Error: Subject already processed (has GLM with ''LO localizer Run 1'' in annotation field), skipping... \n\n');
            fprintf('Error: Subject already processed (has GLM with ''LO localizer Run 1'' in annotation field), skipping... \n\n');
            continue
        end
    end

    %% 2a/b/c. Find datatype number for MotionComp_RefScan1, find scan
    %% numbers for lo localizer scans, record parfiles for these scans and
    %% make sure scan groupings are correct. If everything checks out,
    %% proceed with GLM. If not, SKIP THIS SUBJECT.
    [go,s1]=fmri_loc1_checkDataTypesForGLM(fid,dataTYPES);
    %clear dataTYPES mrSESSION vANATOMYPATH
    
    % If there was a problem in step 3, skip GLM and proceed to next
    % subject
    if go==0
        continue
        
    %% 3. Otherwise, run GLM (to debug: fid=1)
    elseif go==1
        try
            % Initialize a hidden view of the 'inplane' data (like invoking
            % mrVista without a GUI, dataTYPES/etc in workspace)
            hI = initHiddenInplane(s1.mc, s1.scan);
            params.parfiles={s1.parfile}; 
            er_setParams(hI, params, s1.scan, s1.mc); % write params as eventAnalysisParams fields
            tic; [hI, lo_scan] = applyGlm(hI,s1.mc,s1.scangroup,params);
            time=toc;
            fprintf(fid,'GLM COMPLETED -- dt %d, scan %d. Time: %d m %2.2f s \n\n',...
                hI.curDataType,lo_scan,floor(time/60),mod(time,60));
            fprintf('GLM COMPLETED -- dt %d, scan %d. Time: %d m %2.2f s \n\n',...
                hI.curDataType,lo_scan,floor(time/60),mod(time,60));
            glmOK=1;
        catch
            fprintf(fid,'FAILURE TO SUCCESSFULLY RUN GLM \n');
            fprintf('FAILURE TO SUCCESSFULLY RUN GLM \n');
            theerror=lasterror;
            fprintf(fid,'%s \n\n',theerror.message);
            fprintf('%s \n\n',theerror.message);
            glmOK=0;
        end

        %% 4. Compute contrast maps
        if glmOK

            try
                fmri_loc1_computeContrastsLocalizer(hI, lo_scan)
                fprintf(fid,'Computed contrasts using fmri_FFA_computeContrastsLocalizer \n');
                fprintf('Computed contrasts using fmri_FFA_computeContrastsLocalizer \n');
            catch
                fprintf(fid,'FAILURE TO SUCCESSFULLY COMPUTE CONTRASTS \n');
                fprintf('FAILURE TO SUCCESSFULLY COMPUTE CONTRASTS \n');
                theerror=lasterror;
                fprintf(fid,'%s \n\n',theerror.message);
                fprintf('%s \n\n',theerror.message);

            end
        end            
    end
    
    % Fix the annotation and parfile fields for the MotionComp_RefScan
    % dataTYPE, since these are undesirably changed (collateral damage).
    dataTYPES(s1.mc).eventAnalysisParams(s1.scan).annotation='loloc_run1';
   

    par1=dataTYPES(s1.mc).scanParams(s1.scan).parfile;
   
    dataTYPES(s1.mc).eventAnalysisParams(s1.scan).parfiles=par1;
    save(fullfile(thisDir,'mrSESSION.mat'),'mrSESSION','dataTYPES', '-append');
    clear par1 

end

totalTime=etime(clock,startTime); 

fprintf(fid,'\n ------------------------------------------ \n');
fprintf(fid,'Total running time for script: %f minutes \n',totalTime/60);
fprintf('Total running time for script: %f minutes \n',totalTime/60);

fclose(fid); % close out the log file


return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function params=fmri_loc1_setGLMparams(fid,logFileName,scriptName)

% Set GLM parameters: We set the PARAMS struct fields to the values on the
% wiki, which are further explained there. Also we print the values to the
% log. http://vpnl.stanford.edu/internal/wiki/index.php/ROIanalysis#GLMs

fprintf(fid,'\n ------------------------------------------ \n');
fprintf(fid,'\n GLM PARAMETERS \n');
fprintf(fid,' ------------------------------------------ \n');

params=er_defaultParams % Initialize param struct with defaults
p.al='params.alpha=0.0500'; eval(p.al); fprintf(fid,'%s \n',p.al);
p.at='params.ampType=''betas'''; eval(p.at); fprintf(fid,'%s \n',p.at);
p.an='params.annotation=''LO localizer Run 1'''; eval(p.an); fprintf(fid,'%s \n',p.an);
p.ap='params.assignParfiles=0'; eval(p.ap); fprintf(fid,'%s \n',p.ap);
p.bp='params.bslPeriod=[-6 -5 -4 -3 -2 -1 0]'; eval(p.bp); fprintf(fid,'%s \n',p.bp);
p.dt='params.detrend=1'; eval(p.dt); fprintf(fid,'%s \n',p.dt);
p.df='params.detrendFrames=20;'; eval(p.df); fprintf(fid,'%s \n',p.df);
p.ea='params.eventAnalysis=1'; eval(p.ea); fprintf(fid,'%s \n',p.ea);
p.eb='params.eventsPerBlock=6'; eval(p.eb); fprintf(fid,'%s \n',p.eb);
p.fp='params.framePeriod=2'; eval(p.fp); fprintf(fid,'%s \n',p.fp);
p.gt='params.glmHRF=3'; eval(p.gt); fprintf(fid,'%s \n',p.gt);
p.gp='params.glmHRF_params=[6 16 1 1 6 0 24]'; eval(p.gp); fprintf(fid,'%s \n',p.gp);
p.gw='params.glmWhiten=0'; eval(p.gw); fprintf(fid,'%s \n',p.gw); % temporal autocorrelation
p.ic='params.inhomoCorrect=1'; eval(p.ic); fprintf(fid,'%s \n',p.ic);
p.lp='params.lowPassFilter=0'; eval(p.lp); fprintf(fid,'%s \n',p.lp);
p.nb='params.normBsl=1'; eval(p.nb); fprintf(fid,'%s \n',p.nb);
p.od='params.onsetDelta=0'; eval(p.od); fprintf(fid,'%s \n',p.od);
p.pf='params.parfiles='''''; eval(p.pf); fprintf(fid,'%s \n',p.pf); % fill in after checkDataTypes...
p.pp='params.peakPeriod=[4 5 6 7 8 9 10 11 12 13 14]'; eval(p.pp); fprintf(fid,'%s \n',p.pp);
p.sh='params.setHRFParams=0'; eval(p.sh); fprintf(fid,'%s \n',p.sh);
p.sc='params.snrConds=1'; eval(p.sc); fprintf(fid,'%s \n',p.sc);
p.tn='params.temporalNormalization=0'; eval(p.tn); fprintf(fid,'%s \n',p.tn);
p.tw='params.timeWindow=[-6:1:24]'; eval(p.tw); fprintf(fid,'%s \n',p.tw);
p.log=['params.logFile=''' logFileName '''']; eval(p.log); fprintf(fid,'%s \n',p.log)
p.script=['params.scriptName=''' scriptName '''']; eval(p.script); fprintf(fid,'%s \n',p.script)

% params.framePeriod = dataTYPES(dt).scanParams(scan).framePeriod;