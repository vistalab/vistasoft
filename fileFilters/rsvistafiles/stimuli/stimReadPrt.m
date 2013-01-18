function stim = stimReadPrt(prtFiles, TR);
%
% stim = stimReadPrt(prtFiles, [framePeriod=2]);
%
% Read BrainVoyager .prt protocol files into a mrVista stim struct.
%
% If a cell with several file names is provided, will read each into a
% struct array.
%
% ras, 07/06.
if notDefined('prtFiles')
    [f p] = uigetfile({'*.prt' '*.*'}, 'Choose a Brain Voyager .prt file');
    prtFiles = fullfile(p,f);
end

if notDefined('TR'), TR = 2; end

if iscell(prtFiles)
    for i = 1:length(prtFiles)
        stim(i) = stimReadPrt(prtFiles{i});
    end
    return
end

if ~exist(prtFiles, 'file')
    error(sprintf('%s not found. ', prtFiles));
end

fid = fopen(prtFiles, 'r');

%%%%%%%%%%%%%%%
% read header %
%%%%%%%%%%%%%%%
fgetl(fid); % ignore 1st line
stim.fileVersion = fscanf(fid, 'FileVersion: %i\n');

timeUnit = fscanf(fid, 'ResolutionOfTime:%s\n');
if ~isequal(timeUnit, 'Volumes')
    error('Can only read .prt files with time unit of Volumes.')
end

fscanf(fid, 'Experiment:');
stim.experiment = fgetl(fid);

fgetl(fid); % skip line
fscanf(fid, 'BackgroundColor:');
stim.bgColor = str2num(fgetl(fid));

fscanf(fid, 'TextColor:');
stim.textColor = str2num(fgetl(fid)) ./ 255;

fgetl(fid); % skip line
fscanf(fid, 'TimeCourseColor:');
stim.tcColor = str2num(fgetl(fid)) ./ 255;

fscanf(fid, 'TimeCourseThick:');
stim.tcThickness = str2num(fgetl(fid));

fscanf(fid, 'ReferenceFuncColor:');
stim.predictorColor = str2num(fgetl(fid)) ./ 255;
fscanf(fid, 'ReferenceFuncThick:');
stim.predictorThickness = str2num(fgetl(fid));

fgetl(fid); % skip line
stim.nConds = fscanf(fid, 'NrOfConditions:%i\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read onsets for each condition %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
stim.framePeriod = TR;
stim.cond = [];
stim.onsetFrames = [];
stim.onsetSecs = [];
stim.label = {};
lastFrame = 0;
for cond = 1:stim.nConds
	cond
    stim.condNums(cond) = cond - 1;
    stim.condNames{cond} = fgetl(fid)
    nTrials = fscanf(fid, '%i\n', 1)
    for trial = 1:nTrials
        rng = fscanf(fid, '%i %i\n', 2)
        stim.onsetFrames(end+1) = rng(1);
        stim.cond(end+1) = cond - 1;
        stim.label{end+1} = stim.condNames{cond};
        
        % keep tabs on the last frame to be specified
	
			lastFrame = max([lastFrame rng(2)]); 
		
    end
    fscanf(fid, 'Color:');
	fgetl(fid)
    stim.condColors{cond} = str2num(fgetl(fid)) ./ 255;
    fgetl(fid); % skip line
end

% convert units of frames/volumes into units of seconds from scan onset %
[stim.onsetFrames I] = sort(stim.onsetFrames);
stim.cond = stim.cond(I);
stim.label = stim.label(I);
stim.onsetSecs = (stim.onsetFrames - 1) .* TR;

% add an end of run entry at the last frame
stim.onsetFrames(end+1) = lastFrame;
stim.onsetSecs(end+1) = (lastFrame-1) * TR;
stim.cond(end+1) = 0; 
stim.label{end+1} = 'end of run';

fclose(fid);

return
