function newfnames = dicomSortFilenames(fnames)
%
% newfnames = dicomSortFilenames(fnames)
%
% This function sorts dicom filenames by numeric components rather than
% alphaneumeric.
%
% Input
%   fnames    ... filenames, cell array 
%
% Output 
%   newfnames ... filenames, cell array
%
% Example
% 
% fnames = { ...
%     'MR.1.2.840.113619.2.283.4120.7575399.13891.1357163084.989.dcm'
%     'MR.1.2.840.113619.2.283.4120.7575399.13891.1357163084.990.dcm'
%     'MR.1.2.840.113619.2.283.4120.7575399.13891.1357163084.991.dcm'
%     'MR.1.2.840.113619.2.283.4120.7575399.13891.1357163084.992.dcm'
%     'MR.1.2.840.113619.2.283.4120.7575399.13891.1357163084.993.dcm'
%     'MR.1.2.840.113619.2.283.4120.7575399.13891.1357163084.994.dcm'
%     'MR.1.2.840.113619.2.283.4120.7575399.13891.1357163084.995.dcm'
%     'MR.1.2.840.113619.2.283.4120.7575399.13891.1357163084.996.dcm'
%     'MR.1.2.840.113619.2.283.4120.7575399.13891.1357163084.997.dcm'
%     'MR.1.2.840.113619.2.283.4120.7575399.13891.1357163084.998.dcm'
%     'MR.1.2.840.113619.2.283.4120.7575399.13891.1357163084.999.dcm'
%     'MR.1.2.840.113619.2.283.4120.7575399.13891.1357163085.0.dcm'
%     'MR.1.2.840.113619.2.283.4120.7575399.13891.1357163085.1.dcm'
%     'MR.1.2.840.113619.2.283.4120.7575399.13891.1357163085.10.dcm'
%     'MR.1.2.840.113619.2.283.4120.7575399.13891.1357163085.11.dcm'
%     'MR.1.2.840.113619.2.283.4120.7575399.13891.1357163085.12.dcm'
%     'MR.1.2.840.113619.2.283.4120.7575399.13891.1357163085.2.dcm'
%     'MR.1.2.840.113619.2.283.4120.7575399.13891.1357163085.3.dcm'
%     'MR.1.2.840.113619.2.283.4120.7575399.13891.1357163085.4.dcm'
%     'MR.1.2.840.113619.2.283.4120.7575399.13891.1357163085.5.dcm'
%     'MR.1.2.840.113619.2.283.4120.7575399.13891.1357163085.6.dcm'
%     'MR.1.2.840.113619.2.283.4120.7575399.13891.1357163085.7.dcm'
%     'MR.1.2.840.113619.2.283.4120.7575399.13891.1357163085.8.dcm'
%     'MR.1.2.840.113619.2.283.4120.7575399.13891.1357163085.9.dcm' 
%     };
% 
% newfnames = dicomSortFilenames(fnames)
% 
% Copyright Vistalab 2013 writen by JW (and HH)
%
%%

% loop across files

for fnum=1:length(fnames)
    
    % break filenames into cell array of digits, ignoring other characters
    temp = regexp(fnames{fnum},'(\d+)','tokens');

    % if it is the first file, then determine the number of cells and
    % initialize a matrix 'filenumbers'. this matrix can be easily sorted
    % once it contains only numbers
    if fnum==1
        tmp = cellfun(@(x) str2double(x{1}),temp);
        filenumbers = zeros(length(fnames),size(tmp,2));
        
    else
        % otherwise just place the numbers into the matrix 'filenumbers'
        filenumbers(fnum,:) = cellfun(@(x) str2double(x{1}),temp);
        
    end
    
end

% sort the numbers and re-order the files
[~,iii] = sortrows(filenumbers,1:size(filenumbers,2));

newfnames = fnames(iii);

end