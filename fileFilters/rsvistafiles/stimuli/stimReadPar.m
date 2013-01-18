function stim = stimReadPar(pth,secsPerScan);
% Read stimulus information from a .par file into an (incomplete)
% stim struct. (use stimLoad to get the full struct.)
%
% stim = stimReadPar([pth],[secsPerScan]);
%
% .par file format:
% paradigm (.par) files are adapated from FS-FAST format, and I like 
% to use them because they're easy to read--just tab-delimited text).
% For mrVista 2.0, I've added the ability to read in some fields that
% are not in the older .files, however. A full description can 
% be found in parFormatDescription.
% 
% Input: the input path can be a string specifying the location of 
% one .par file, or a cell specifying the location of many .par files.
% In the latter case, the files will be read as if they specified a set
% of experiments in sequence, and will return a stim struct in which 
% onset times continued ramping up. I.e., the first event of the second
% .par file will follow the last event of the first .par file.
%
% secsPerScan: Optional argument which can either be a single integer
% or an array the same size as the # of par files. This specifies how
% long the fMRI data associated with each par file is: the code will
% manually insert a null (condition 0) event at that time. 
%
% Output: the stim struct will have the following fields:
%
%   parfiles: cell of paths to the parfiles. [char]
%   parfileNames: file names of each parfile, minus the path. [char]
%   onsetSecs: onset times in seconds. [double]
%   condition: condition # of each event [int16]
%   labels: label for each event [char]
%   colors: color for each event [char]
%   user1 and user2: user-defined 6th and 7th columnns [char]
%
% NOTE: This code only does part of the job of loading stimulus files.
% stimLoad does the other part: converting onset times into mr frames
% relative to an mr object or scan.
%
% ras, 08/05
if ~exist('pth','var') | isempty(pth),
    pth = mrSelectDataFile('stayput','r','*.par',...
                        'Select .par file to read...');
end

if ~exist('secsPerScan','var'), secsPerScan = []; end

if iscell(pth), stim = stimReadManyPar(pth,secsPerScan); return; end

if ~exist(pth,'file') & ~strncmp(pth(end-3:end),'.par',4)
    pth = [pth '.par'];
end

% if the file still isn't found, it may be given relative to 
% the directory pwd/Stimuli:
if ~exist(pth,'file')
    pth = fullfile(pwd,'Stimuli',pth);
end

% if still can't find it, give up
if ~exist(pth,'file')
    [a b c] = fileparts(pth);
    error(sprintf('%s%s does not exist',b,c));
end

[fidPar message] = fopen(pth,'r');

if fidPar==-1
  disp(message)
  error(['ERROR: problem reading .par file ' pth '.']);
end

onsetSecs = []; conds = []; labels = {}; colors = {}; images = {};
user1 = {}; user2 = {};
while ~feof(fidPar)
    ln = fgetl(fidPar);
    
    % separate values by tabs
    vals = explode(char(9),ln); % char(9) is TAB
    
%     % gum, sometimes 2nd tab is missing
%     if length(vals)<3 & findstr(vals{2},'  ')
%         tmp = explode('   ',vals{2}); 
%         if length(tmp)>1, vals{2}=tmp{1}; vals{3}=tmp{2}; end
%     end
    
    onsetSecs(end+1) = str2num(vals{1});
    conds(end+1) = str2num(vals{2});
    
    if length(vals) > 2,
        labels{end+1} = vals{3};
    else
        labels{end+1} = [];
    end
    
    if length(vals) > 3
        colors{end+1} = vals{4};
    else
        colors{end+1} = [];
    end

    if length(vals) > 4
        images{end+1} = vals{5};
    else
        images{end+1} = [];
    end

    if length(vals) > 5
        user1{end+1} = vals{6};
    else
        user1{end+1} = [];
    end

    if length(vals) > 6
        user2{end+1} = vals{7:end};
    else
        user2{end+1} = [];
    end
end

% initialize stim struct
[p f ext] = fileparts(pth);
stim.stimFiles = {pth};
stim.stimFileNames = {f};

% sort by onsetSecs, so rows need not
% be in chronological order
[stim.onsetSecs I] = sort(onsetSecs);

% assign fields to stim struct
stim.conds = int16(conds(I));
stim.labels = labels(I);
stim.colors = colors(I);
stim.images = images(I);
stim.user1 = user1(I); 
stim.user2 = user2(I);

% if the # of seconds per scan is specified, set that
% as the last event:
if ~isempty(secsPerScan)
    cutOff = find(stim.onsetSecs>secsPerScan);
    if ~isempty(cutOff)
        I = setdiff(1:length(onsetSecs),cutOff);
        stim.onsetSecs = stim.onsetSecs(I);
        stim.conds = conds(I);
        stim.labels = labels(I);
        stim.colors = colors(I);
        stim.images = images(I);
        stim.user1 = user1(I); 
        stim.user2 = user2(I);    
    end
    stim.onsetSecs(end+1) = secsPerScan;
    stim.conds(end+1) = 0;
    stim.labels{end+1} = 'end of run';
    stim.colors{end+1} = '';
    stim.images{end+1} = '';
    stim.user1{end+1} = ''; 
    stim.user2{end+1} = '';      
end

stim.run = repmat(1, size(stim.onsetSecs));

% close the file
fclose(fidPar);

return
% /--------------------------------------------------------------------/ %




% /--------------------------------------------------------------------/ %
function stim = stimReadManyPar(pth,secsPerScan);
% loop across many par files, reading each in turn
stim.stimFiles = pth; stim.stimFileNames = {};
stim.onsetSecs = []; stim.conds = []; stim.labels = {}; stim.colors = {};
stim.images = {}; stim.user1 = {}; stim.user2 = {}; stim.run = [];
for i = 1:length(pth),   
    if isempty(secsPerScan)
        % not specified -- take all onset events
        run = stimReadPar(pth{i});
    elseif length(secsPerScan)==length(pth)
        % specified separately for each parfile
        run = stimReadPar(pth{i},secsPerScan(i));
    else
        % single duration specified for all parfiles
        run = stimReadPar(pth{i},secsPerScan);
    end
    
    stim.stimFileNames{i} = run.stimFileNames{1};
    
    % augment onsetSecs of all runs after the first
    if i > 1, run.onsetSecs = run.onsetSecs + stim.onsetSecs(end); end
    
    % concatenate other fields
    stim.onsetSecs = [stim.onsetSecs run.onsetSecs];
    stim.conds = [stim.conds run.conds];
    stim.labels = [stim.labels run.labels];
    stim.colors = [stim.colors run.colors];
    stim.images = [stim.images run.images];
    stim.user1 = [stim.user1 run.user1];
    stim.user2 = [stim.user2 run.user2];     
    stim.run = [stim.run i*ones(size(run.onsetSecs))];    
end


return
