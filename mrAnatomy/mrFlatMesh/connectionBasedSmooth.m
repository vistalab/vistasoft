function smoothedVals=connectionBasedSmooth(connectionMatrix,inputVals)
% Performs neighborhood averaging of the values in inputVals.
%
% smoothedVals = connectionBasedSmooth(connectionMatrix,inputVals)
% 
% connectionMatrix specifies which nodes in inputVals are connected. 
% Each element in inputVals is replaced by the mean of itself and its neigbours.
% 
% AUTHOR: Wade
% Date written : 06-16-03
% example : smoothedVals=connectionBasedSmooth(connectionMatrix,inputVals);
%
%

inputVals=inputVals(:);
[sy sx]=size(connectionMatrix);

if (sx~=length(inputVals))
    error('Connection matrix and inputVal size mis-match: %d (cm) %d (input)',sx,length(inputVals));
end

connectionMatrix=(connectionMatrix~=0); % We do our own normalization
sumNeighbours=sum(connectionMatrix,2); % Although it should be symmetric, we specify row-summation
smoothedVals=double(connectionMatrix)*double(inputVals);
smoothedVals=smoothedVals./sumNeighbours;

return;
