function vw=loadAnat(vw,pathStr)
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

mrGlobals;

switch viewGet(vw,'View Type')
    
case 'Inplane',

    if ~exist('pathStr','var') %If does not exist, default to mrSESSION
        pathStr = sessionGet(mrSESSION,'Inplane Path');
    end
    if ~exist('pathStr','var') || isempty(pathStr)
        error('No path has been specified or found in mrSESSION.');
    end
    if ~exist(pathStr,'file')
        error(['No file at the location: ',pathStr]);
    else
        %ip = orientInplane(vw, pathStr);
        vw = viewSet(vw,'Anat Initialize',pathStr);
    end
    
case {'Volume','Gray','generalGray'}
    if ~exist('pathStr','var'), pathStr = vANATOMYPATH;   end
    if ~exist(pathStr,'file'), pathStr = getVAnatomyPath; end
    [anat, vw.mmPerVox, ~, ~, ni] = readVolAnat(pathStr); 
    anat = scaleVolAnat(anat, ni);
	vw = viewSet(vw, 'anat', uint8(anat)); % if not uint8...
    
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

