function mtrResampleSISPathways(fgFilenames,samplerOptsFilename,numSamples,fgResampledFilename,bCalcStats)

% Run metrotrac
% mtrResampleSISPathways({'paths_newpdf.dat'},'met_params.txt',1000000,'res
% amp_newpdf.dat',1);
%% MUST MAKE SURE THIS PROGRAM IS COMPILED AND IN RIGHT LOCATION
if(ispc)
    executable = which('updatestats.exe');
else
    error('Not compiled for Linux.');
end

% Get importance weight file that we need to resample with
for ii = 1:length(fgFilenames)
    statvec_names{ii} = sprintf('temp%d_statvec_iw.dat',ii);
    if( bCalcStats )
        args = sprintf(' -v %s -i %s -o temp.dat -s 4 -sf %s', samplerOptsFilename, fgFilenames{ii}, statvec_names{ii});
        cmd = [executable args];
        disp(cmd); disp('...')
        [s, ret_info] = system(cmd,'-echo');
        disp('Done')
    end
end

% Resample
%resampleSISPathways(numSamples, {'temp_statvec_iw.dat'}, {fgFilename},
%fgResampledFilename);
resampleSISPathways(numSamples, statvec_names, fgFilenames, fgResampledFilename);

if( bCalcStats )
    % Cleanup temp files
    delete('temp.dat');
end

% for ii = 1:length(statvec_names)
%     delete(statvec_names{ii});
% end

return;

function resampleSISPathways(numSamples, weightFilenames, pdbInFilenames, pdbOutFilename)

numFiles = length(weightFilenames);
sizeFiles = [];


% Load multiple importance weight files
iw = [];
for f = 1:numFiles
    iwtemp = mtrLoadStatvec(weightFilenames{f});
    iw = [iw; iwtemp];
    sizeFiles(f) = length(iwtemp);
end
iw(isnan(iw)) = -Inf;
iw = exp(iw);

% Resample pathways according to normalized weight
sample_ind = randsample([1:length(iw)],numSamples,true,iw);
unique_sample_ind = unique(sample_ind);
unique_sample_w = 0;
for i = 1:length(unique_sample_ind)
    unique_sample_w(i) =  sum(sample_ind == unique_sample_ind(i));
end

pdbtemp = [];
% Load the pathways and create resampled database
for f = 1:numFiles
    disp('Loading Pathway Database...');
    pdbtemp{f} = mtrPathwayDatabase();
    pdbtemp{f} = loadDatabase(pdbtemp{f},pdbInFilenames{f});
end


% create new database
pdb = mtrPathwayDatabase();
pdb = pdbtemp{1};
sub_unique_sample_ind = unique_sample_ind( unique_sample_ind <= length(pdbtemp{1}.pathways) & unique_sample_ind > 0);
pdb.pathways = pdbtemp{1}.pathways(sub_unique_sample_ind);

for f = 2:numFiles
    unique_sample_ind = unique_sample_ind - sizeFiles(f-1);
    sub_unique_sample_ind = unique_sample_ind( unique_sample_ind <= length(pdbtemp{f}.pathways) & unique_sample_ind > 0);
    pdb.pathways = [pdb.pathways pdbtemp{f}.pathways(sub_unique_sample_ind)];
end
% Clear statistic headers
pdb.pathway_statistic_headers = [];

% Create statistic header of just new weights
is_luminance_encoding = 1;
is_computed_per_point = 0;
is_viewable_stat = 1;
agg_name = 'resampleWeight';
local_name = 'NA';
uid = '1';
pdb = addStatisticHeader(pdb,agg_name,local_name,is_luminance_encoding, is_computed_per_point, is_viewable_stat, 1);

% Add the weight data to the path
for p = 1:length(pdb.pathways)
    pdb.pathways(p).path_stat_vector = unique_sample_w(p);
end

% Save out resampled database
disp('Saving new resampled database...');
saveDatabase(pdb,pdbOutFilename);


return;