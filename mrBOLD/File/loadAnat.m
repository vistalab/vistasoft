function vw=loadAnat(vw,inplanePath)
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

switch viewGet(vw,'View Type')
    
case 'Inplane',
    if ~exist('inplanePath','var')
        myErrorDlg(['No path specified. Please specify the path.']);
    end
    if ~exist(inplanePath,'file')
        myErrorDlg(['No ',inplanePath,' file']);
    else
        %fprintf('Loading anatomies from %s ...',pathStr);
        vw.anat = niftiRead(inplanePath); 
        %fprintf('done.\n');
    end
    
case {'Volume','Gray','generalGray'}
    if ~exist('pathStr','var'), inplanePath = vANATOMYPATH;   end
    if ~exist(inplanePath,'file'), inplanePath = getVAnatomyPath; end
    [vw.anat vw.mmPerVox] = readVolAnat(inplanePath); 
	vw.anat = uint8(vw.anat); % if not uint8...
    
case 'SS',
    if ~exist('pathStr','var')
        if ~exist(fullfile(HOMEDIR,'RawDicom','Anatomy','SS'))
            inplanePath = fullfile(HOMEDIR,'Raw','Anatomy','SS');
        else inplanePath = fullfile(HOMEDIR,'RawDicom','Anatomy','SS');
        end
    end
    disp(['loading anatomies matrices from ',inplanePath]);
    % vw.anat = ReadMRImage(fullfile(pathStr,'I.001'));
    % Instead of I.001, now read whatever comes up as the first I* file
    SSfile = dir(fullfile(inplanePath,'I*'));
    if ~isempty(SSfile);
        vw.anat = double(ReadMRImage(fullfile(inplanePath,SSfile(1).name)));
    else % if no SS file exists, still create a fake vw.anat
        disp('Did not find valid SS files. Ignore...');
        vw.anat = zeros(64);
    end
    
case 'Flat'
    if ~exist('pathStr','var')
        inplanePath=fullfile(viewDir(vw),'anat.mat');
    end
    if exist(inplanePath,'file')
        load(inplanePath);
    else
        anat = makeFlatAnat(vw);
        save(inplanePath,'anat'); 
    end
    vw.anat = anat;
   
end % switch

return;

