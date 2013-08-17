function relaxPlotHistogram(file,vector, color)
% relaxPlotHistogram(file, vector) 
% This function plots a histogram
% given a NIFTI file and a range of values for the histogram
%
% Usage:
% relaxPlotHistogram('file.nii.gz', linspace(0, 2, 100))

if (nargin ==2) 
    color = 'b';
end


histData = niftiRead(file);
histogram = hist(histData.data(histData.data(:)>0), vector);
plot (vector, histogram, color);
