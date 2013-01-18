function [class,classFile] = GetClassFile(view, hemisphere,nameOnly)
%Find class data and the class file name for a Gray view
%
%    [classData,classFileName] = GetClassFile(view, hemisphere);
%
% The name of the file is usually specified in the view structure.  If it
% is not specified, or it doesn't exist, some guesses are made and finally
% the user is queried.  This routine is used by the viewGet routine.  
%
% Note that the returned data is a structure of class data information.  We
% probably need a way to address the information in the class structure,
% view classCreate/Set/Get.  I don't think those routines exist yet.
%
% Examples:
%   vw = VOLUME{1};
%   data = viewGet(vw,'classdata','left');
%   cFile = viewGet(vw,'classFileName','right');
%   
% 2003.09.20 RFD (bob@white.stanford.edu) we now get the full classification, 
%   not restircted to voi. We can always restrict to VOI ourselves using header.
% 2004.01.10 BW.  Many changes.
%

global mrSESSION;

if ~strcmp(viewGet(view,'viewType'),'Gray'), error('Class files only exist for Gray views.'); end
if ieNotDefined('hemisphere'), hemisphere = 0; end
if ieNotDefined('nameOnly'), nameOnly = 0; end

% We start out not knowing the class data or file name
class = [];
classFile = [];

% See if the class file name is stored in the structure.  If so, retrieve
% it.
if (hemisphere == 1), 
    hname = 'right';
    if checkfields(view,'rightClassFile')
        classFile = view.rightClassFile; 
    end
elseif (hemisphere ==0),  
    hname = 'left';
    if checkfields(view,'leftClassFile')
        classFile = view.leftClassFile; 
    end
else    
    error('Bad hemisphere specification.  Must be 0 (left) or 1 (right).');
end

% If the file exists and the user only wanted the name, return.
if (exist(classFile,'file') && nameOnly), return; end

% The file may not exist, or the user may want data.  If the file doesn't
% exist, try this.  It could be a sub-routine at this bottom called guess
% file name.
if ~exist(classFile,'file')
    knownClassFile = 0;
	
	% try to guess a reasonable start directory:
	% as we migrate over to the NIFTI format, where both 
	% left and right class files are in the same file, we can
	% omit searching for an [anat]/Left or [anat]/Right dir. 
	% But I'm leaving this in for now. (-ras, 02/20/08)
    anatPath = getAnatomyPath(mrSESSION.subject);
	startDir = [anatPath filesep hname];
	if ~exist(startDir, 'dir')
		startDir = anatPath;
	end
		
	filters = { '*.*',	'All files'; ...
				'*.Class;*.class', 'Class files'; ...
				'*.nii.gz;*.nii;*.NII.GZ;*.NII', 'NIFTI files' };
	prompt = ['Select ' hname ' class file...'];
	
    [name, path] = myUiGetFile(startDir, filters, prompt);
	
    if name == 0
        class = []; classFile = []; return;
    else
        classFile = fullfile(path, name); 
    end
else
    knownClassFile = 1;
end

% If even this newly selected file doesn't exist, send back an empty file
% name.
if ~exist(classFile, 'file')
    classFile = []; 
    return; 
elseif nameOnly
    % The file exists.  The user doesn't want the data.
    return; 
else
    % The file exists.  The user wants the data.  Get the data. Then put the
    % name of the class file into the Gray\coords.mat file.
	class = readClassFile(classFile, 0, 0, hemisphere);
    coordsFile = viewGet(view,'coordsfilename');
    
    if exist(coordsFile,'file')
        switch hname
            case 'left'
                leftClassFile = classFile;
                if ~knownClassFile
                    fprintf('Adding leftClassFile to coords.mat %s\n',leftClassFile);
                    save(coordsFile,'-append','leftClassFile'); 
                end
            case 'right'
                rightClassFile = classFile;
                if ~knownClassFile, 
                    fprintf('Adding rightClassFile to coords.mat %s\n',rightClassFile);
                    save(coordsFile,'-append','rightClassFile'); 
                end
            otherwise
                error('Bad name.')
        end
    else
        warndlg('No Gray\coords.mat file.  Class file name not appended.');
    end
end

return;
