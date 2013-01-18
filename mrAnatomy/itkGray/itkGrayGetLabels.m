function labels      = itkGrayGetLabels(labelFile)
% Parse an ITK label file
% labels      = itkGrayGetLabels(labelFile)
% 
% Label files contain 8 fields about each class (or label) in an ITK class
% file. These are the classes:
% ################################################
% # ITK-SnAP Label Description File
% # File format: 
% # IDX   -R-  -G-  -B-  -A--  VIS MSH  LABEL
% # Fields: 
% #    IDX:   Zero-based index 
% #    -R-:   Red color component (0..255)
% #    -G-:   Green color component (0..255)
% #    -B-:   Blue color component (0..255)
% #    -A-:   Label transparency (0.00 .. 1.00)
% #    VIS:   Label visibility (0 or 1)
% #    IDX:   Label mesh visibility (0 or 1)
% #  LABEL:   Label description 
% ################################################
% 
% Example: labels = itkGrayGetLabels(labelFile);
%
% JW: 7/2010

if ~exist(labelFile, 'file')
    warning('[%s]: File %s does not exist', mfilename, labelFile)
    labels = [];
    return
end

% open the file
fid     = fopen(labelFile,'r');

% read the text
txt     = textscan(fid,'%f%f%f%f%f%f%f%s','CommentStyle','#','Delimiter','\t');

labels = struct([]);
% get the fields
for ii = 1:length(txt{1})
    labels(ii).layer   = txt{1}(ii);
    labels(ii).col     = [txt{2}(ii) txt{3}(ii) txt{4}(ii)];
    labels(ii).alpha   = txt{5}(ii);
    labels(ii).vis     = txt{6}(ii);
    labels(ii).mshvis  = txt{7}(ii);
    labels(ii).name    = txt{8}(ii);
end

% close the file
fclose(fid);

% remove annoying quotes from labels.name
for l = 1:numel(labels)
    labels(l).name = regexprep(labels(l).name, '"', '');
    labels(l).name = labels(l).name{1};
end

end