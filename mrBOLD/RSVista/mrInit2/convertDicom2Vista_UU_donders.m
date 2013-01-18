function convertDicom2Vista_UU_donders(subjectName,SessionName,dicomServer)
% convertDicom2Vista_UU_donders(subjectName,SessionName,dicomServer) 
%
% adapted from prepareUCSFParnassusUniversal
%
% e.g. prepareUCSFParnassusUniversal('norcia','LOCMT',2);
% The 1st argument is the subject name (corresponds to that subject's
% anatomy directory under /raid/MRI/anatomy/
% The 2nd argument is a plain text string to tag the exam. Avoid slashes,
% minus signs, spaces etc.
% The third argument indicates which dicom server the data came from. In
% theory we can auto-detec this but for now use
% 1: For NIC data via MPRAGE
% 2: For NIC data via Hurricane
% 3: For Donders' data
%
%
% This is a script to recon the dicom files that come from the UCSF MRI
% scanner at China Basin
% The first part uses the medcon program to convert those files into
% analyze format. After that, we use FSL to do some preprocessing like
% motion correction.
% The final step is to generate a mrLoadRet project from the set of 4d
% Analyze files.
% Motion correction is performed in several stages: We first do within-scan
% MC and store all the resulting transform matrices for each scan. Then we
% do between-scan MC using the mean image from each scan to align everything to the
% first scan in the session. We store the transforms for these alignments
% as well.
%
% Then we go back and combine the within and between scan transforms and
% re-apply the entire transform to the original data set. In this way we
% avoid re-sampling the original data more than we have to.
% EXAMPLE: prepareUCSF('appelbaum','LOC_Localizer');
% 2006.04.20 Mark Schira wrote it (mark@ski.org)
% 2007.06.13 Alex Wade modified it for use with data from Parnassus NIC
% Siemens scanner. Uses some ideas from dicom2analyze_v4.m : SPM and GazLab
% people
% Issue is that Siemens system uses mosaic image format: Each dicom file
% has an entire volume in it sometimes (and sometimes not in the case of
% anatomies..)
% The SPM5 routine dicom2analyze takes care of this.
% The critical step is...
%  % convert dicoms to analyzer
%        hdr = spm_dicom_headers(files);
%        spm_dicom_convert(hdr,opts,root_dir,format);
% Rather than using medcon (great though medcon is!)
% This 'universal' version is supposed to cope with the slightly different
% filename conventions in the two DICOM suervers 'hurricane' and 'MPRAGE'
% 080907: Can now use any directory names inside the RawDicom subdirectory

%%

% we need spm
if(isempty(which('spm_dicom_headers')))
    error('Requires spm2+ tools!');
end

if not(exist('subjectName','var'))
    error('need the lastname of subject as input');
end

if not(exist('SessionName','var'))
    SessionName='Whatever';
end

if not(exist('dicomServer','var'))
    error ('You must  specify a dicom server index: 1 is UCSF NIC / MPRAGE, 2 is UCSF NIC / Hurricane, 3 is Donders Institute');
end

ActionList={'Nothing','Inplanes','Functional','RefFunc','Anatomical','DTI'}; 

%%  Opening dialogs
% We present the user with a list of options. Not all stages have to be
% performed at once.

initOptions = {'clean previous files (be careful!)',...
    'DB Query',...
    'Do Detect data',...
    'Generate MLR structure',...
    'Generare BV structure',...
    'Motion cor. in scan',...
    'Motion cor. between scan',...
    'Perform blocked analysis',...
    'Perform event related analysis',...
    'Clean up, delete analyze files',...
    'Clean up. Zip the Dicom files',...
    };
initReply=[0 0 1 1 0 0 0 0 0 0 0]; % These are the defaults
initReply = buttondlg('mrInit UU-Data', initOptions,initReply);
if isempty(initReply), return; end

pause(0.2);
cleanfirst=initReply(1);
doDBQuery=initReply(2); %#ok<NASGU>
detectData=initReply(3);
doMLR=initReply(4);
doBV=initReply(5);%#ok<NASGU>
motionInScan=initReply(6);%#ok<NASGU>
motionBetween=initReply(7);%#ok<NASGU>
blockedData=initReply(8);%#ok<NASGU>
eventData=initReply(9);%#ok<NASGU>
doCleanUp=initReply(10);%#ok<NASGU>
doPackDicom=initReply(11);%#ok<NASGU>

baseDir = pwd;

%% we use some unix commands
operatingSystem=computer;
if not(strcmp(operatingSystem(1:4),'GLNX'))
    error('This function  is for Linux machines only');
end

%% remove analyze file from previous runs

if cleanfirst
    ! rm ./*/*/*/*.hdr
    ! rm ./*/*/*/*.img
    ! rm -r ./Inplane
    ! rm -r ./Gray
    ! rm -r ./Volume
    ! rm mrSESSION*.mat
    ! rm prepare*vars.mat
end

%% Automatic detection of the Directories, Inplanes etc
if detectData
    disp('Reading the directory structure...');
    RawDir = './Raw/Functionals/';
    baseDirListing=dir(RawDir);

    % Sort this so that it is in ascending numeric order
    nDirs=length(baseDirListing);
    tempDirName=zeros(nDirs,1);

    for t=1:length(baseDirListing);
        switch dicomServer
            case {1,3}		% MPRAGE
                tempDirNum = str2double( baseDirListing(t).name(find(baseDirListing(t).name=='_',1,'last')+1:end) );


            otherwise
                tempDirNum=str2double(baseDirListing(t).name);
        end

        if (tempDirNum>0) && isfinite(tempDirNum)
            tempDirName(t)=tempDirNum;
        end

    end

    [tempDirName,i]=sort(tempDirName); % Because we don't know how DIR might order the output
    baseDirListing=baseDirListing(i); % Apply the sort

    baseDirListing=baseDirListing(3:end); % Strip off stuff that didn't start with a number - like . and ..
    disp({baseDirListing.name}')
    
    foundScans(1).DirName='';
    foundScans(1).Files=0;
    foundScans(1).Slices=0;
    foundScans(1).Volumes=0;
    foundScans(1).Sequence='';
    foundScans(1).Action='';
    foundScans(1).Filenames='';
    foundScans(1).SkipVols='';
    foundScans(1).Cycles='';
    foundScans(1).Filename4d='';
    foundScans(1).lastfile='';
    
    inplanedir=0;

    for thisEntry=1:length(baseDirListing)
        fprintf('\nProcessing %d',thisEntry);

        if baseDirListing(thisEntry).isdir

            thisdir=baseDirListing(thisEntry).name;
            
            switch dicomServer
                case 1 % Coming from MPRAGE at the NIC
                    tempdir=dir([baseDir,filesep,RawDir,filesep,baseDirListing(thisEntry).name,filesep,'*.dcm']); % Only list the Dicom files.
                case 2 % Coming from Hurricane
                    tempdir=dir([baseDir,filesep,RawDir,filesep,baseDirListing(thisEntry).name,filesep,'*.DCM']); % Only list the Dicom files.
                case 3 % Coming from Donders
                     tempdir=dir([baseDir,filesep,RawDir,filesep,baseDirListing(thisEntry).name,filesep,'*.IMA']); % Only list the Dicom files.
                otherwise
                    error('No valid dicomServer type specified');
            end
           
            foundScans(thisEntry).RawDir = RawDir;
            foundScans(thisEntry).DicomServer = dicomServer;
            foundScans(thisEntry).Filenames=tempdir(1).name;
            foundScans(thisEntry).Filenames=...
            foundScans(thisEntry).Filenames(1:find(foundScans(thisEntry).Filenames=='I'));
            foundScans(thisEntry).DirName=baseDirListing(thisEntry).name;
            foundScans(thisEntry).Files=length(tempdir);
            header=dicominfo([baseDir,filesep,RawDir,filesep,baseDirListing(thisEntry).name,filesep,tempdir(1).name]);
            if (isfield(header,'Private_0019_100a')) % This is a functional image stored in Mosaic format
                disp(tempdir);
                foundScans(thisEntry).Slices=header.Private_0019_100a;%Private_0021_104f;
                foundScans(thisEntry).Volumes=(length(tempdir));%/foundScans(thisdir).Slices;
            else % Otherwise it's a T1 image stored slice-wise
                foundScans(thisEntry).Slices=(length(tempdir));
                foundScans(thisEntry).Volumes=1;
            end



%             if (sum(findstr(header.SeriesDescription,'ep2d'))) && (foundScans(thisEntry).Volumes>40) % Currently, this is hard-coded. We should be more flexible in case we change the protocol name.
            if (~isempty(strfind(header.SeriesDescription,'ep2d')) || ~isempty(strfind(header.SeriesDescription,'bas_MoCo'))) && (foundScans(thisEntry).Volumes>40) % Currently, this is hard-coded. We should be more flexible in case we change the protocol name.
                foundScans(thisEntry).Action='Functional';
            else
                foundScans(thisEntry).Action='Nothing';
            end
            if strcomp(header.SeriesDescription,'inplanes')
                inplanedir=thisdir;
            end

            foundScans(thisEntry).Sequence=header.SeriesDescription;

        end
    end
    if not(inplanedir==0)
        foundScans(inplanedir).Action='Inplanes';
    else
        disp(sprintf('[%s]:No Inplanes found',mfilename));
    end
    foundScans=selectInitParameters(foundScans);

else %if not scan the directory one would have to read the info from a previous run
  
    foundScans=selectInitParameters(foundScans);
end

%% The above does seem to work quite well. Now we can pass the dir names
% into the SPM5 dicom converters to generate NIFTI or ANALYZE format
% data...
%
% Recon all the functionals to Analyse

disp(sprintf('[%s]:Reconning all scans...',mfilename));drawnow;
procScans = cell(numel(foundScans),1);
hdrList   = cell(numel(foundScans),1);
for thisDir=1:numel(foundScans)
    if strcmp(foundScans(thisDir).Action,'Functional') ||  strcmp(foundScans(thisDir).Action,'RefFunc')
        tic
        [procScans{thisDir},hdrList{thisDir}]=Dicom2Analyze_SPM5(foundScans(thisDir));
        toc
    end
end
% 
% 
% for thisDir=1:length(foundScans)
%     if strcmp(foundScans(thisDir).Action,'Inplanes') ||  strcmp(foundScans(thisDir).Action,'Anatomical')
%         outFileName=[foundScans(thisDir).Filenames,'_a4d.hdr']; % We will generate a 3d analyze (Nifti) file from anatomicals
% 
%         tic
%         [procScans{thisDir},hdrlist{thisDir}]=Dicom2ThreeDAnalyze_SPM5(foundScans(thisDir),pwd,dicomServer);
%         toc
% 
%     end
% end
% datestr(now)
% clear thisDir:


%%

cd (baseDir)
if doMLR
    disp('Making directories');
    !mkdir Inplane
    !mkdir Volume
    !mkdir Gray
end


save prepareUUvars

status=mrInitRetFromSPM(foundScans,subjectName,SessionName);

disp('Result of mrInitRetFromSPM');
disp(status);

if blockedData
    mrvista('inplane');
    inplane=getSelectedInplane;
    inplane=computeMeanMap(inplane,0);
    inplane=computeCorAnal(inplane,0);
    inplane = selectDataType(inplane,2);
    inplane=computeMeanMap(inplane,0);
    inplane=computeCorAnal(inplane,0);
    %    closeInplaneWindow();
    datestr(now)
end


