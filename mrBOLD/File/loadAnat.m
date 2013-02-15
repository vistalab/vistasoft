function vw=loadAnat(vw,inplanePath)
%
% vw=loadAnat(vw,[pathStr])
%
% Loads anatomies and fills anat field in the view structure.
% Load anat now reads in niftis in the Inplane view and automatically
% applies and computes the necessary transform. In the inplane, no longer
% loads or saves from/to 1.0anat.mat
%
% vw = VOLUME: loads vAnatomy.dat via loadVolAnat
% path: optional arg to specify a pathname for the anatomy file
%
% djh, 1/9/98
%
% rmk, 9/17/98 added SS case
%
% 2.26.99 - Get anatomy path from getAnatomyPath - WAP

%global mrSESSION; Removed global variable since not used
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
        vw.anat = niftiRead(inplanePath);
        %Let us also calculate Voxel Size
        vw.anat = niftiSet(vw.anat,'Voxel Size',prod(niftiGet(vw.anat,'pixdim')));
        %Let us also calculate and and apply transform
        vw.anat = niftiApplyAndCreateXform(vw.anat,'Inplane');
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

