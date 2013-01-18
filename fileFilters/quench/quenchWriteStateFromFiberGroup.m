function quenchWriteStateFromFiberGroup(fg,t1File,outName)
% 
%   quenchWriteStateFromFiberGroup([fg],[t1File],[outName])
% 
% OVERVIEW: Takes a mrDiffusion fiber group and associated t1File and
%           creates a Quench '.qst' state file using the fg.subgroup field
%           to identify different group assignments in Quench.
% 
% NOTE:
%           This function saves an accompanying pathway database file
%           (.pdb) that will be loaded in quench when the state file is
%           loaded. The T1 file can be stored anywhere as the full path is
%           written to the sate file - the pdb file and the qst files are
%           saved, and should be stored, in the same directory. 
% 
% INPUTS:
%       fg      -  a mrDiffusion fiber structure: can be a filename (.mat)
%                  with a subgroup field wherein each distinct fiber is
%                  given an idex unique to the fibergroup it belongs to.
%                  The field fg.subgroupNames should have the names for
%                  each of the unique fiber groups indexed. 
%       
%       t1File  -  full path to t1 file. Important: Do not use symbolic
%                  links. If you use a symbolic link in linux then we can
%                  resovle the link, but in windows or MAC you're on your
%                  own.
%       
%       outName -  the stem for the qst and pdb filenames. If not provided
%                  the name will be taken from fg.name.
% 
% WEB RESOURCES:
%       mrvBrowseSVN('quenchWriteStateFromFiberGroup');
% 
% 
% EXAMPLE USAGE:
% 
%   Default usage: Provide path to fiber group and t1 file - take name
%                  from fiber group.
%       >> fg = 'MoriGroups.mat';
%       >> t1File = '/some/Path/t1File.nii.gz';
%       >> quenchWriteStateFromFiberGroup(fg,t1File,[]);
% 
% (C) Stanford University, VISTA Lab 2012
% 


%% Check inputs and open file for writing

% Fiber group
if notDefined('fg')
    fg = mrvSelectFile('r','*.mat','QST: Select fiber group',pwd); 
    if isempty(fg); return; end
end

% Check that fg is a struct or a file that we can read in
if ~isstruct(fg) && exist(fg,'file')
    fprintf('Reading fiber group structure from file...');
    fg = fgRead(fg);
    fprintf('done.\n')
elseif isfield(fg,'fg.fibers')
    disp('Fiber group structure already loaded.');
end


% Check for subroups and subgroup names fields. If they don't exist however
% the fiber group structure contains an array of fiber groups then convert
% it into the desired format. Otherwise exit the function
if ~isfield(fg,'subgroup') && ~isfield(fg,'subgroupNames') && length(fg) > 1
    fg = dtiFgArrayToFiberGroup(fg);
elseif ~isfield(fg,'subgroup') && length(fg) <=1
    error('No subgroup field found in fibergroup structure!');
elseif ~isfield(fg,'subgroupNames') && length(fg) <=1
    error('No subgroupNames field found in fiber structure!');
end

% T1 File
if notDefined('t1File')
    t1File = mrvSelectFile('r','*.nii*','QST: Select t1File',pwd);
    if isempty(t1File); return; end
else
    [p f e] = fileparts(t1File);  
    if isempty(p)
        disp('WARNING: t1File must be a full path to the t1File - NOT A SYMBOLIC LINK!!!!');
        t1File = mrvSelectFile(r,'.nii.gz','Choose t1File',pwd);
        if isempty(t1File); return; end
    end 
end

% Check that t1File is not a soft link:
if isunix  
    [status t1File] = system((sprintf('readlink -f %s',t1File)));
    if status ~= 0
        disp('Could not resolve real path to t1File');
    end
else
    disp('NON-UNIX system detected: Could not verify the path of the t1File - make sure that t1File is not a symbolic Link.')
end

% If outname is not supplied then we use the fg.name field and make sure 
% that the extension is not yet attached
if notDefined('outName')
    outName = fg.name; 
end

[path file ext] = fileparts(outName); 

if ~isempty(ext)
    outName = fullfile(path,file);
end

% Remove any spaces in the file name and replace with '_'
outName = regexprep(outName,'\W','_');


%% Set color and name assignments

% Get the information we need to do the assignments
fgInds    = fg.subgroup; 
numGroups = numel(unique(fgInds));

disp([num2str(numGroups) ' fiber groups will be written to the state file:']);

% Number of unique colors used by default in Quench = 16
num       = 1:16; 
cinds     = repmat(num,1,(round(numGroups/16)+1));

% Build cell array of colors for color assignments
c{1}='0.0784314 0.352941 0.784314 1';
c{2}='0.596078 0.305882 0.639216 1';
c{3}='1 1 0.2 1';
c{4}='0.301961 0.686275 0.290196 1';
c{5}='0.745098 0.156863 0.156863 1';
c{6}='1 0.498039 0 1';
c{7}='0.470588 0.705882 0.705882 1';
c{8}='0.470588 0.392157 0.196078 1';
c{9}='0.564706 0.705882 1 1';
c{10}='0.831373 0.682353 0.854902 1';
c{11}='0.964706 0.964706 0.690196 1';
c{12}='0.678431 0.87451 0.670588 1';
c{13}='0.913725 0.607843 0.607843 1';
c{14}='0.976471 0.784314 0.611765 1';
c{15}='0.756863 0.882353 0.882353 1';
c{16}='0.780392 0.737255 0.635294 1';

% Loop over the groups and assign the color
for ii = 1:numGroups
    color{ii} = c{cinds(ii)}; 
end

% Name assignments: Check group names field and build group name cell array
% for displaying each of the names
for ii = 1:numGroups
    if numGroups == length(fg.subgroupNames)
        gname{ii} = fg.subgroupNames(ii).subgroupName;
        % Remove any spaces in the file names and replace with '_'
        gname{ii} = regexprep(gname{ii},'\W','_');
        fprintf(' %s - %s\n',num2str(ii),gname{ii});
    else
        error('Length of subgroupNames is not == to the number of subgroups');
    end
end


%% Start writing the huge, annoying text file
%  Note that quench is INCREDIBLY picky about line endings and spaces.
%  Things have to be just as they are below or Quench will CRASH - hard. 

fprintf('Writing Quench state file [%s.qst] ... ', outName);

% Open the state file for writing
qst = fopen([outName '.qst'],'wt');

        fprintf(qst,'Version 2\n');

        fprintf(qst,'--- Main Window ---\n');
        fprintf(qst,'Position 1865 52\n');
        fprintf(qst,'Size 1088 915\n');
        fprintf(qst,'Is Maximized 0\n');
        fprintf(qst,'Current background image index 0\n');

        fprintf(qst,'\n--- Volumes ---\n');
        fprintf(qst,'Num Volumes :1\n');
        fprintf(qst,'%s\n', t1File); % This has to be the full path to the t1. 

        fprintf(qst,'--- PDB Info ---\n');
        fprintf(qst,'Num PDB''s: 1\n');
        fprintf(qst,'%s\n',[outName '.pdb']); % This could be the full path to the fiber group

        fprintf(qst,'--- Pathway Assignment ---\n');
        fprintf(qst,'Locked: 0\n');
        fprintf(qst,'Selected Group: 1\n');
        fprintf(qst,'Num Assigned: %s\n',num2str(numel(fgInds)));

        % Convert the fgInds matrix to a string and remove the brackets
        indstr      = mat2str(fgInds);
        indstr(1)   = [];
        indstr(end) = [];
        fprintf(qst,'%s \n',indstr); % the trailing space is important!!!

        fprintf(qst,'\n--- Pathway Groups ---\n');
        fprintf(qst,'Num Groups: %s\n',num2str(numGroups+1)); % This should be +1
        fprintf(qst,'Name: Trash\n');
        fprintf(qst,'Color: 0.501961 0.501961 0.501961 1\n');
        fprintf(qst,'Visible: 1\n');
        fprintf(qst,'Active: 1\n\n');

        % Loop over the groups and write out the unique names and colors
        for ii = 1:numGroups
            fprintf(qst,'Name: %s\n', gname{ii});
            fprintf(qst,'Color: %s\n', color{ii});
            fprintf(qst,'Visible: 1\n');
            fprintf(qst,'Active: 1\n\n');
        end
        
        % Not sure that these positions will work for every screen
        fprintf(qst,'Camera Position: -503.393,-16.364,26.7371\n');
        fprintf(qst,'Camera View Up: 0.0488575,-0.000488639,0.998806\n');
        fprintf(qst,'Camera Focal Point: 0.062871,-13.8796,2.11129\n');

        fprintf(qst,'--- Move tool ---\n');
        fprintf(qst,'Position: (0,0,0)\n');
        fprintf(qst,'Scale :(19.8361,19.8361,19.8361)\n');
        fprintf(qst,'Visible : 0\n');

        fprintf(qst,'--- Scale tool ---\n');
        fprintf(qst,'Position: (0,0,0)\n');
        fprintf(qst,'Scale :(19.8361,19.8361,19.8361)\n');
        fprintf(qst,'Visible : 0\n');

        fprintf(qst,'\n--- Volume State ---\n');
        fprintf(qst,'Volume Section"s Position: 0,-18,18\n');
        fprintf(qst,'Volume Section"s Visibility: 1,1,1\n');
        fprintf(qst,'Active Image :1\n');

        fprintf(qst,'\n--- Overlays ---\n');
        fprintf(qst,'Num overlay items :1\n');
        fprintf(qst,'Opacity :1\n');
        fprintf(qst,'Range :0 32767\n');
        fprintf(qst,'ColorMapIndex :0\n');
        fprintf(qst,'Visible :0\n');

        fprintf(qst,'\n--- Gesture Panel ---\n');
        fprintf(qst,'Visible :1\n');
        fprintf(qst,'Position :(755,4)\n');
        fprintf(qst,'SelectMode :0\n');

        fprintf(qst,'\n--- Selection Panel ---\n');
        fprintf(qst,'Visible :1\n');
        fprintf(qst,'Position :(857,4)\n');
        fprintf(qst,'SelectMode :0\n');

        fprintf(qst,'\n--- Refine Selection panel ---\n');
        fprintf(qst,'Position -1 -1\n');
        fprintf(qst,'Size 450 260\n');
        fprintf(qst,'Visible 0\n');
        fprintf(qst,'Num ROIs 0\n');

        fprintf(qst,'\n--- Background and overlay panel ---\n');
        fprintf(qst,'Position -1 -1\n');
        fprintf(qst,'Size 458 250\n');
        fprintf(qst,'Visible 0\n');

        fprintf(qst,'\n--- ROIs ---\n');
        fprintf(qst,'Num ROIs: 0\n\n');

fclose(qst);

fprintf('done.\n');



%% Save the fiber group struct as a pdb

fprintf('Writing pathway database [%s.pdb] ... ', outName);

fgWrite(fg,outName,'pdb')

fprintf('done! \n');


return




%%
%#ok<*ASGLU> 
%#ok<*AGROW>
%#ok<*NASGU>
