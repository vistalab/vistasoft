function mtrResampleMultiSISPathways(fgFilenames,samplerOptsFilenames,numSamples,fgResampledFilenames)
%
%
%
%
%
%
%

%% Run metrotrac
% MUST MAKE SURE THIS PROGRAM IS COMPILED AND IN RIGHT LOCATION
if ispc
    executable = which('updatestats.exe');
elseif strcmp(computer,'GLNXA64')
    executable = which('updatestats.glxa64');
else
    error('Not compiled for this platform: %s.',computer);
end

if ~iscell(fgFilenames)
    fgFilenames{1} = fgFilenames;
end
if ~iscell(samplerOptsFilenames)
    samplerOptsFilenames{1} = samplerOptsFilenames;
end
if ~iscell(fgResampledFilenames)
    fgResampledFilenames{1} = fgResampledFilenames;
end

numFgFile        = length(fgFilenames);
numSamplerOpt    = length(samplerOptsFilenames);
numResampFgFName = length(fgResampledFilenames);

if numSamplerOpt ~= numResampFgFName
    error('Number of entries must be the same for samplerOptsFilenames & fgResampledFilenames!');
end

pdbtemp = cell(numFgFile,1);

% load the pathways
for ii = 1:numFgFile
    disp('Loading Pathway Database ... (Could take a while!)');
    pdbtemp{ii} = mtrPathwayDatabase();
    pdbtemp{ii} = loadDatabase(pdbtemp{ii},fgFilenames{ii});
end

for ii = 1:numSamplerOpt
    cSamplerOptFName = samplerOptsFilenames{ii};

    statvec_names = cell(numFgFile,1);

    for jj = 1:numFgFile
        % get importance weight file that we need to resample with
        statvec_names{jj} = sprintf('temp%d_statvec_iw.dat',jj);
        args = sprintf(' -v %s -i %s -o temp.dat -s 4 -sf %s', cSamplerOptFName, fgFilenames{jj}, statvec_names{jj});
        cmd = [executable args];
        disp(cmd);
        disp('...')
        system(cmd,'-echo');
        disp('Done')

        % resample
        resampleSISPathways(numSamples, statvec_names, pdbtemp, fgResampledFilenames{ii});
    end
end

% cleanup temp files
delete('temp.dat');
for ii = 1:length(statvec_names)
    delete(statvec_names{ii});
end

return

%% sub-function
function resampleSISPathways(numSamples, weightFilenames, pdbInFiles, pdbOutFilename)

% load multiple importance weight files
numFiles  = length(weightFilenames);
iw        = [];
sizeFiles = zeros(numFiles,1);
for ii = 1:numFiles
    iwtemp        = mtrLoadStatvec(weightFilenames{ii});
    iw            = [iw; iwtemp];
    sizeFiles(ii) = length(iwtemp);
end
iw = exp(iw);

% resample pathways according to normalized weight
sample_ind        = randsample(1:length(iw),numSamples,true,iw);
unique_sample_ind = unique(sample_ind);
unique_sample_w   = zeros(length(unique_sample_ind),1);

for ii = 1:length(unique_sample_ind)
    unique_sample_w(ii) =  sum(sample_ind == unique_sample_ind(ii));
end

% create new database
pdb                   = pdbInFiles{1};
sub_unique_sample_ind = unique_sample_ind( unique_sample_ind <= length(pdbInFiles{1}.pathways) & unique_sample_ind > 0);
pdb.pathways          = pdbInFiles{1}.pathways(sub_unique_sample_ind);

for ii = 2:numFiles
    unique_sample_ind     = unique_sample_ind - sizeFiles(ii-1);
    sub_unique_sample_ind = unique_sample_ind( unique_sample_ind <= length(pdbInFiles{ii}.pathways) & unique_sample_ind > 0);
    pdb.pathways          = [pdb.pathways pdbInFiles{ii}.pathways(sub_unique_sample_ind)];
end

% clear statistic headers
pdb.pathway_statistic_headers = [];

% create statistic header of just new weights
is_luminance_encoding = 1;
is_computed_per_point = 0;
is_viewable_stat      = 1;
agg_name              = 'resampleWeight';
local_name            = 'NA';
uid                   = '1';

pdb = addStatisticHeader(pdb,agg_name,local_name,is_luminance_encoding, is_computed_per_point, is_viewable_stat, uid);

% add the weight data to the path
for ii = 1:length(pdb.pathways)
    pdb.pathways(ii).path_stat_vector = unique_sample_w(ii);
end

% Save out resampled database
disp('Saving new resampled database...');
saveDatabase(pdb,pdbOutFilename);

return
