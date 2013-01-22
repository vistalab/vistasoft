function vw=loadAnat(vw,pathStr)
%
% vw=loadAnat(vw,[pathStr])
%
% Loads anatomies and fills anat field in the view structure. 
% vw = INPLANE: loads anat.mat
% vw = VOLUME: loads vAnatomy.dat via loadVolAnat
% path: optional arg to specify a pathname for the anatomy file
%
% djh, 1/9/98
%
% rmk, 9/17/98 added SS case
%
% 2.26.99 - Get anatomy path from getAnatomyPath - WAP

global mrSESSION; %TODO: Remove the global variable calls here that are not used
global HOMEDIR;
global vANATOMYPATH;

switch viewGet(vw,'View type')
    
case 'Inplane',
    if ~exist('pathStr','var')
        pathStr=fullfile(viewDir(vw),'anat.mat'); %Expects an anat.mat to be saved there
                                                  %Change this to point to
                                                  %a nifti file
    end
    if ~exist(pathStr,'file')
        myErrorDlg(['No ',pathStr,' file']);
    else
%         fprintf('Loading anatomies from %s ...',pathStr);
        load(pathStr);
        %TODO: Change this to ReadNifti or the real version of it
        vw.anat = anat;
%         fprintf('done.\n');
    end
    
case {'Volume','Gray','generalGray'}
    if ~exist('pathStr','var'), pathStr = vANATOMYPATH;   end
    if ~exist(pathStr,'file'), pathStr = getVAnatomyPath; end
    [vw.anat vw.mmPerVox] = readVolAnat(pathStr); 
	vw.anat = uint8(vw.anat); % if not uint8...
    
case 'SS',
    if ~exist('pathStr','var')
        if ~exist(fullfile(HOMEDIR,'RawDicom','Anatomy','SS'))
            pathStr = fullfile(HOMEDIR,'Raw','Anatomy','SS');
        else pathStr = fullfile(HOMEDIR,'RawDicom','Anatomy','SS');
        end
    end
    disp(['loading anatomies matrices from ',pathStr]);
    % vw.anat = ReadMRImage(fullfile(pathStr,'I.001'));
    % Instead of I.001, now read whatever comes up as the first I* file
    SSfile = dir(fullfile(pathStr,'I*'));
    if ~isempty(SSfile);
        vw.anat = double(ReadMRImage(fullfile(pathStr,SSfile(1).name)));
    else % if no SS file exists, still create a fake vw.anat
        disp('Did not find valid SS files. Ignore...');
        vw.anat = zeros(64);
    end
    
case 'Flat'
    if ~exist('pathStr','var')
        pathStr=fullfile(viewDir(vw),'anat.mat');
    end
    if exist(pathStr,'file')
        load(pathStr);
    else
        anat = makeFlatAnat(vw);
        save(pathStr,'anat'); 
    end
    vw.anat = anat;
   
end % switch

return;

