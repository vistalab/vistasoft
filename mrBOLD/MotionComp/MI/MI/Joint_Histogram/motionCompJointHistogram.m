function H = motionCompJointHistogram(image1,image2,N,ROI)
%
%    H = motionCompJointHistogram(image1, image2, [N], [ROI])
%
% gb 02/22/05
%
% Creates the joint histogram of length N of two images whose intensity are
% integers between 0 and N. ROI is the region of interest where the error
% has to be computed.

if ieNotdefined('N')
    N = max(image1(:),image2(:));
end

if ~isequal(size(image1),size(image2))
    error('The images must have the same size to compute the joint histogram');
end

if ieNotDefined('ROI')
	ROI = ones(size(image1));
else
    if ~isequal(size(ROI),size(image1))
        ROI = reshape(ROI,size(image1));
    end
end
    
H = zeros(N,N);

for i = 1:length(image1)
    a = double(image1(i)) + 1;
    b = double(image2(i)) + 1;
    H(a,b) = H(a,b) + ROI(i);
end