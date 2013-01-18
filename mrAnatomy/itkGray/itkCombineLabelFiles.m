function itkCombineLabelFiles(inpaths,outpath, labels)

% itkCombineLabelFiles(inpaths,outpath,[labels])
%
% Purpose
%   Combine two or more itkGray label files. If there is an input variable
%   'labels' (a cell array), then the input files will be scanned for
%   labels with only those values. If the 'labels' is not an input
%   variable, then use all non-zero labels in each input file.
%   The output label file will assign new label values, starting from 1 and
%   incrementing.
%
% Input
%   inpaths - paths to input label files (cell array)
%   outpath - path to newly created label file (string)
%   labels  - cell array of labels numbers (integers) in each input label
%               file (length of labels and length of inpaths must be equal)
%
% Example:
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
% See also itkCombineSegmentationFiles.m
%
% RFB 2009 [renobowen@gmail.com]
% JW  2010: modified to allow arbitrary number of input paths



% Pre-allocate space for variables
fid  = zeros(1,length(inpaths));
text = cell(1,length(inpaths));

% Generate file identifiers and textscan outputs for each file
for fileNum=1:length(inpaths)
    fid(fileNum)     = fopen(inpaths{fileNum},'r');
    text{fileNum}    = textscan(fid(fileNum),'%f%f%f%f%f%f%f%s','CommentStyle','#','Delimiter','\t');
end

% Open a separate file to write the new labels into
fidNew = fopen(outpath,'w+');

% Generate the header for the file
fprintf(fidNew,   '################################################   \n');
fprintf(fidNew,   '# File format:                                     \n');
fprintf(fidNew,   '# IDX   -R-  -G-  -B-  -A--  VIS MSH  LABEL        \n');
fprintf(fidNew,   '# Fields:                                          \n');
fprintf(fidNew,   '#    IDX:   Zero-based index                       \n');
fprintf(fidNew,   '#    -R-:   Red color component (0..255)           \n');
fprintf(fidNew,   '#    -G-:   Green color component (0..255)         \n');
fprintf(fidNew,   '#    -B-:   Blue color component (0..255)          \n');
fprintf(fidNew,   '#    -A-:   Label transparency (0.00 .. 1.00)      \n');
fprintf(fidNew,   '#    VIS:   Label visibility (0 or 1)              \n');
fprintf(fidNew,   '#    IDX:   Label mesh visibility (0 or 1)         \n');
fprintf(fidNew,   '#  LABEL:   Label description                      \n');
fprintf(fidNew,   '################################################   \n');
fprintf(fidNew,   '0\t0\t0\t0\t0\t0\t0\t"Clear Label"\n');

% if the label numbers are not given as input, then look them up from the
% files
if ~exist('labels', 'var')
    % get any non-zero label from each of the label files
    for fileNum = 1:length(paths)
        inds = text{fileNum}{1} > 0;
        labels{fileNum} = text{fileNum}{1}(inds);
    end
end

% Start counting new label indices

% Start the counter for new labels. We will make the labels go from 1 to
% nlabels without skipping any numbers (even if there were skipped numbers
% in the original files)
newLabelInd = 1;

% For each file
for fileNum=1:length(inpaths)
    % And for each label
    for label=1:length(text{fileNum}{1})
        
        thisrow = text{fileNum}{1}(label);
        if ~ismember(thisrow, labels{fileNum})
            % do nothing, we are not interested in this label
        else
            % Loop across the eight entries
            for entry=1:8
                contents = text{fileNum}{entry}(label); % Set aside the contents
                if entry==1 % If it's the first entry, we're using our new label index instead of the old one
                    contents = newLabelInd;
                end
                if isfloat(contents) % If it's a floating point, write it as such
                    fprintf(fidNew,'%0.0f\t',contents);
                else % If it's not a floating point, write it as a string
                    fprintf(fidNew,'%s\t',cell2mat(contents));
                end
            end
            fprintf(fidNew,'\n'); % Start a new line when we've finished with all of the entries for a label
            newLabelInd = newLabelInd + 1; % Increment the new label indeces
        end
    end
end

% Close the files we read from as we're complete
for fileNum=1:2
    fclose(fid(fileNum));
end
% Close the new file as we've filled it with the necessary info
fclose(fidNew);