function [niOUT labels] = itkCombineSegmentationFiles(inpaths, outpath)
% Combine data from two or more nifti (ITK-gray) segmentation files
%    [niOUT labels] = itkCombineSegmentationFiles(inpaths, outpath)
%
% Example using this function and the related function, itkCombineLabelFiles:
%   inpaths{1}  = pathToMyNiftiSegmentationFile;
%   inpaths{2}  = pathToMyOtherNiftiSegmentationFile;
%   outpath     = pathToMyNewCombinedNiftiSegmentationFile;
%   [ni labels] = itkCombineSegmentationFiles(inpaths, outpath);
%
%   inpath{1}   = pathToMyLabelFile;
%   inpath{2}   = pathToMyOtherLabelFile;
%   outpath     = pathToMyNewLabelFile'
%   itkCombineLabelFiles(inpath, outpath, labels);
%
% See also itkCombineLabelFiles.m
%
% JW: April, 2009

%% How many files to combine?
nFiles  = length(inpaths);
labels  = cell(1, nFiles);

%% Get the nifti Files

% The label numbers in the input segmentation files can be any integers.
% They might skip numbers, and they might overlap (that is, two or more
% input files might use the same labels). To stay organized, we will
% renumber the labels in the new, combined segmentation file, as
% consecutive integers starting from 1.

% To start, the highest label is 1. Then incremement with each new label.
highestlabel = 1;

% Loop through each input segmentation file

for ii = 1:nFiles
    niIN        = niftiRead(inpaths{ii});

    % create the output file if not yet made
    if ii == 1
        niOUT       = niIN;
        niOUT.data  = zeros(size(niIN.data), 'uint16');
        niOUT.fname = outpath;

    end

    % Check the data class
    niIN.data = uint16(niIN.data);
    
    % Get the unique label values (non-zero integers) in the input file
    labels{ii} = sort(unique(niIN.data(niIN.data > 0)));    

    % Don't overwrite existing labels. This will ensure priority
    % for the input files in ascending order (inpaths{1} has greatest
    % priority, etc.)
    availableInds = niOUT.data == 0;
    
    % Find all voxels in niIN with each label, and then copy to niOUT
    for l = 1:length(labels{ii})
        thislabel = labels{ii}(l);
        inds = niIN.data == thislabel & availableInds;
        niOUT.data(inds) = highestlabel;
        highestlabel = highestlabel +1;
    end
end

% Save it
writeFileNifti(niOUT)

% Done
return
