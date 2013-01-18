function [meanMap,stdMap,TcircSq,p]=computeStatsOnComplexVectors(cVectors)
% [meanMap,stdMap]=computeStatsOnComplexVectors(cVectors)
% PURPOSE : Computes the mean and std along the 3rd dimension 
%   on a 3D or 4D set of complex vectors 
%   produced by getSingleCycleVectors or getSingleCycleVectorsMultipleScans
%   It's almost redundant except that if you pass in a 4D array, it
%   reshapes to a 3D array before computing the std and mean along the 3rd
%   dimension.
  
s=size(cVectors);
if (length(s)==4)
    cVectors=reshape(cVectors,[s(1),s(2),s(3)*s(4)]);
end
s=size(cVectors);
if (length(s)~=3)
    error('S must be a 3 or 4D array');
end

meanMap=mean(cVectors,3);
stdMap=std(cVectors,[],3);

zeroMean=cVectors-repmat(meanMap,[1,1,s(3)]);


rStd=sum(real(zeroMean).^2/s(3),3);
iStd=sum(imag(zeroMean).^2/s(3),3);

Vindiv=(rStd+iStd)/(2*(s(3)-1));

Vgroup=(s(3)/2)*(abs(meanMap).^2);
TcircSq=(1/s(3))*(Vgroup./Vindiv);
p=FTest(2,(2*s(3)-2),s(3)*TcircSq);

return
