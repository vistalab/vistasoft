function quenchWriteFibersFromState(stateFile,fg,fgBins,outName,outType)
% 
% quenchWriteFibersFromState([stateFile],[fg],[fgBins],[outName],[outType='pdb'])
% 
% OVERVIEW: Take a quench state file and from that file read the unique
%           subgroup indices and save out a fiber group (pdb) for each 
%           unique value. 
% 
% NOTE:
%           This function will be parsing out a text file. If the text file
%           has been altered in any way this will fail spectacularly. 
% 
% INPUTS:
%       stateFile - a Quench stateFile. -- if there is one qst file in the
%                   directory where this function is called then it
%                   will be selected and used. If there are multiple then
%                   it will prompt the user if it's not provided.
% 
%       fg        - a pbd fiber group associated with the qst file. This
%                   will be read in from the qst file. If the fg is not
%                   within the same directory then the user will be
%                   prompted if not provided.
%       
%       fgbins    - The bins in the qst for each of the fiber groups user
%                   wants pulled out of the state file. Defaults to all.
%       
%       outName   - A [numel(fgBins) X 1] cell array containing the pdb 
%                   filenames. If not provided the names will be taken from
%                   the qst file by default. 
% 
%       outType   - Type of file to save out: 'pdb' or 'mat' 
% 
% WEB RESOURCES:
%       mrvBrowseSVN('quenchWriteFibersFromState');
% 
% 
% EXAMPLE USAGE:
% 
%   1. Default usage where the '.qst' and '.pdb' file are in the same
%      directory and only one '.qst' file exists.
%       >> quenchWriteFibersFromState;
% 
%   2. Same as 1 above, but return only bins 1 4 8 from the 'qst' file and
%      retain the names used within the 'qst' file:
%       >> quenchWriteFibersFromState([],[],[1 4 8],[],[]);
% 
%   3. Same as 2, but give each group a specific name:
%       >> quenchWriteFibersFromState([],[],[1 4 8],{'fg_1','fg_2','fg_3'},[]);
% 
%   4. Provide all inputs:
%       >> sateFile = 'greatFileName.qst';
%       >> fg = 'greatFileName.pdb';
%       >> fgBins = [1 12 29];
%       >> outName = {'fg_1','fg_2','fg_3');
%       >> outType = 'pdb';
%       >> quenchWriteFibersFromState(stateFile,fg,fgBins,outName,outType);
% 
% 
% (C) Stanford VISTA, 2012 [lmp]
% 


%% Check inputs

% QST file: If there is only one qst file in the CWD then we load that one
% If there is more than one prompt user for the file
if notDefined('stateFile')
    qstName = dir('*qst');
    s = size(qstName);
    if s(1) > 1
       disp('More that one Quench state file found in this directory... Opening dialog...');
        stateFile = mrvSelectFile('r','*.qst','Selcte QUENCH state file',pwd);
    else
       stateFile = fullfile(pwd,qstName.name);
    end
end

% Check that fg is a struct or a file that we can read in
% Perhaps we should read this in later, when we need it.
if notDefined('fg')
    fg = [];
end

% Set outname to empy if they didn't pass it in - we'll set it later
if notDefined('outName')
    outName = '';
end

% They didn't pass in fGroups so we set it to empty and use all unique
% values later
if notDefined('fgBins')
   fgBins = [];
end

% By default we save out pdb files
if notDefined('outType')
    outType = 'pdb';
end


%% Read the qst file

% Open the state file for reading
qst = fopen(stateFile,'r');

% Find out how many lines are in the qst text file
num = 1; 
tline = fgetl(qst);
while ischar(tline)
   tline = fgetl(qst);
   num   = num+1;
end
fclose(qst);

% Open the file back up for reading  
qst = fopen(stateFile,'r');

% Loop over the file and read each line individually into a cell array - Q 
Q = cell(1,num);
for ii = 1:num
   tline = fgetl(qst);
   Q{ii} = tline;   
end

fclose(qst);

% Q is now a cell array containing each line of the qst file
Q = Q';



%% Load the fiber group and begin to parse the Quench State .qst file

% If the user did not pass in a fiber group then 'fg' will be empty and we
% will try to load the fiber group from the path listed within the quench
% state file
if isempty(fg)
    disp('Loading fibers from path in the ''qst'' file...');
    fg = Q{14}; % The path in the qst file
    try
        fg = fgRead(fg);
    catch ME
        % That didn't work so we prompt the user to select the fiber group
        disp(ME);
        fg = mrvSelectFile('r','*.pdb','Select PDB file',pwd);
        fg = fgRead(fg);
    end
    
% It's not empty and it's a file - load it. 
elseif ~isstruct(fg) && exist(fg,'file')
    disp('Loading fibers from file ...');
    fg = fgRead(fg);

% It was passed in as a structure - so we're done
elseif isfield(fg,'fibers')
    disp('Fibers already loaded.');
end

% Sanity check: Check the number of inds against the number of fibers in
% fg.fibers
if str2num(Q{18}(15:end)) ~= numel(fg.fibers) 
    error('The number of fibers referenced in the ''qst'' file does not match that of the fiber group passed in!')
end

% The fiber indices from the qst file
fInds = str2num(Q{19}); 

% The unique fiber group indices
fGroups = unique(fInds);

% The total number of fiber groups
nGroups = numel(fGroups);


%% Get names for the fiber groups

% Initialize the fName cell array
fName = cell(nGroups,1);

% Set up the fName cell array for naming each fiber group
if notDefined('outName') || numel(outName) ~= numel(fgBins)
    % Starting number of lines before first name. Names occur every 5 lines.
    nind = 28; 
    for nn = 1:nGroups
        % Remove any spaces in the file names and replace with '_'
        fName{nn} = regexprep(Q{nind}(7:end),'\W','_');
        % Increase the line ind by 5 each pass.
        nind = nind+5; 
    end
else
    fName = outName;
end

% If outName was not passed in but fgBins are reuested then take those
% fgBins out of the fNames structure ans use only those for the names
if notDefined('outName') && ~notDefined('fgBins');
   outName = fName(fgBins);
   fName   = outName;  
end


%% Create the fiber groups and write them out

fprintf('Creating %s groups from ''qst'' file...',num2str(numel(fGroups)));

% The ID of unique fiber group bins - if passed in then use those
if ~notDefined('fgBins')
   fGroups = fgBins;
end


% For each unique fg index in fgGroups assign the fibers to a new group and
% write them out
for ff = 1:numel(fGroups)
    
    % fgI are the indices for a given fibergroup (ff) - fInds is the long
    % array of indices from the state file
    fgI = find(fInds == fGroups(ff)); 
    
    % Keep only fgI from fg.fibers
    fgOut = fgExtract(fg,fgI,'keep');
    
    % Set the name from the fName cell array
    fgOut.name = fName{ff}; 
    
    % Show the user what's going on
    fprintf('\n  %s - %s',num2str(ff), fName{ff});
    
    % Save out the fiber group
    fgWrite(fgOut,fgOut.name,outType);  
    
    % Clear for memory
    clear fgOut
end

fprintf('\nDone.\n'); 


return




%%
%#ok<*ST2NM>


