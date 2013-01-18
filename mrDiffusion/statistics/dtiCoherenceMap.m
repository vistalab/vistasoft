function coherenceMap = dtiCoherenceMap(dt6File, connectivityDegree)
%Compute voxelwise coherence map
%
% coherenceMap = dtiCoherenceMap(dt6File, connectivityDegree)
%
% Coherence metric is computed of tensor vectors, not values. If tensor
% orientation in a voxel is similar to that in its neighbours (6, 18 or
% 26), coherence metric gives a greater value.
%
% Example:
%     dt6File = '/biac3/wandell4/data/reading_longitude/dti_y1/vh040719/dti06trilinrt/dt6.mat';
%     connectivityDegree=6;
%     coherenceMap=dtiCoherenceMap(dt6File, connectivityDegree)
%
% (c) Vistalab

% HISTORY
% Bob and Elena wrote it 02/2010

dt = dtiLoadDt6(dt6File);

[vec,val] = dtiEig(dt.dt6);
% Avoid negative eigenvalues
val(repmat(dt.brainMask,[1 1 1 3]) & val<=0) = 1;
val = log(val);
logDt6 = dtiEigComp(vec,val);
if(~isreal(logDt6)), error('logDt6 can''t be complex!'); end

%T_VecUnscaled=zeros(size(logDt6));

switch connectivityDegree
    case 6

        shiftsize = [-1 0 0; 1 0 0; 0 -1 0; 0 1 0 ];
    case 18
        NHOOD=ones(3, 3, 3); NHOOD(2, 2, 2)=0; NHOOD([1 3], [1 3], [1 3])=0; %Use this one for 18-connectivity
        [i, j, k] = ind2sub([3 3 3], find(NHOOD(:)));
        shiftsize = [i-2 j-2 k-2];

    case 26
        NHOOD=ones(3, 3, 3); NHOOD(2, 2, 2)=0;
        [i, j, k] = ind2sub([3 3 3], find(NHOOD(:)));
        shiftsize = [i-2 j-2 k-2];

    otherwise
        error('connectivityDegree should be 6, 18 or 26');
end


logDt6neigh=zeros([size(logDt6) size(shiftsize, 1)]);
fprintf(1, 'Finding neighbourhoods of connectivity degree %d \n', connectivityDegree);
for iShift=1:size(shiftsize, 1)
    logDt6neigh(:, :, :, :, iShift) = circshift(logDt6,[shiftsize(iShift, :) 0]);
end
coherenceMap = computeCoherence(logDt6, logDt6neigh);
showMontage(coherenceMap); title(['dti vector coherence for connectivity degree of ' num2str(connectivityDegree)]);

end

function cohIm=computeCoherence(logDt6, neigh)
fprintf(1, 'Computing coherence map \n');
N1 = size(neigh,5);
q = size(neigh, 4);                 % should be 6
p = (-1 + sqrt(1+8*q))/2;       % should be 3

N2 = 1;
N = N1+N2;
M1 = mean(neigh,5);
M2 = logDt6;
M = (N1*M1 + N2*M2)/N;
[V1,L1] = dtiEig(M1);
[V2,L2] = dtiEig(M2);
[V,L] = dtiEig(M);

d1 = neigh - repmat(M1,[1 1 1 1 N1]);
d1(:,:,:,p+1:q,:) = sqrt(2)*d1(:,:,:,p+1:q,:);
S1 = sum(sum(d1.^2, 4), 5)/(q*(N1-1));
    
Ssq = ((N1-1)*S1)/(N-2); % + (N2-1)*S2.^2)/(N-2) -- this part we dont need because N2=1;
df(1) = q-p; % for a tensor with 6 unique elements, df = 3

preT = N * sum(((N1*L1 + N2*L2)/N).^2 - L.^2, 4);
LRT = (1/df(1)) * preT./(Ssq); 

% We need to normalize this to make a nice image. Armin claims that
% this metric is F distributed with df(q-p, q(N-2)). So, try
% linearizing with finv.

figure; hist(LRT(:), 100); 
cohIm =finv(LRT,df(1), q*(N-2));
end
