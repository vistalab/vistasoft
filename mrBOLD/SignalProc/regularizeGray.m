function result = regularizeGray(input,nodes,edges,lambda,tol,maxiters)
%
% result = regularizeMap(view,input,lambda)
%
% input: data from one scan, e.g.,
%    co(:,1) or  z = amp(:,1).*exp(i*ph(:,1))
% can have NaNs indicating no data (e.g., for voxels below cothresh)
%
% nodes:  8xN array of (x,y,z,num_edges,edge_offset,layer,dist,pqindex).
%
% edges:  1xM array of node indices.  The edge_offset of
%    each node points into the starting location of its set
%    of edges.
% where N, M are the number of nodes, edges in the graph.
%
% lambda: smoothness coefficient
%
% result^{i+1}[x] = c2[x] s^i[x]               data missing
% 		  = c1[x] (input[x] + lambda s^i[x])     otherwise
% 
% c_1[x] = 1/(1 + numNeighbors * lambda)
% c_2[x] = 1/numNeighbors
% s[x] = sumNeighbors

% Defaults for tol and maxiters
%
if ~exist('tol','var')
  tol = 1e-2;
end
if ~exist('maxiters','var')
  maxiters = 100;
end

% Get indices for missing data
%
NaNs=find(isnan(input));
notNaNs=find(~isnan(input));

% Initialize result
%

numNodes = length(input);
result = zeros(size(input));
result(notNaNs) = input(notNaNs);
newresult = zeros(size(input));

% Get numNeighbors and compute c1 and c2
%
numNeighbors = double(nodes(4,:));
edges        = double(edges);

edgeOffsets = double(nodes(5,:));
c1 = 1 ./ (1 + lambda*numNeighbors);
c2 = 1 ./ numNeighbors;
c2(find(numNeighbors==0)) = 0;
c = zeros(size(input));
c(notNaNs) = c1(notNaNs);
c(NaNs) = c2(NaNs);

% Initialize iterations
%
inputSD=std(input(notNaNs));
snr=Inf;
iter=0;

waitHandle = mrvWaitbar(0,'Smoothing data.  Please wait...');
while ((snr>tol) & (iter<maxiters))
   mrvWaitbar(iter/maxiters)
   iter = iter+1;
   
   % Compute sumNeighbors
   sumNeighbors = sumOfNeighbors(real(result),edges,edgeOffsets,numNeighbors) + ...
      j*sumOfNeighbors(imag(result),edges,edgeOffsets,numNeighbors);

   
   newresult(NaNs) = c(NaNs) .* sumNeighbors(NaNs);
   newresult(notNaNs) = c(notNaNs) .* (input(notNaNs) + lambda*sumNeighbors(notNaNs));
   

   % Compute snr (stopping criterion)

   snr=sqrt(mean(abs(newresult-result).^2))/inputSD;
   result=newresult;
end
close(waitHandle);

if (iter >= maxiters)
   disp(['Warning: maximum number of iterations exceeded: ',num2str(maxiters)]);
end

return;

%%% Test code

mrLoadRet

% open volume window
% switch to gray mode
% load anatomy
% view phase

% coronal slice 60

curScan = getCurScan(VOLUME{1});
amp = VOLUME{1}.amp(:,curScan);
co = VOLUME{1}.co(:,curScan);
ph = VOLUME{1}.ph(:,curScan);
z = co.*exp(i*ph);

zthresh = z;
belowThreshIndices = find(co<.2);
zthresh(belowThreshIndices) = NaN;

result = regularizeGray(zthresh,VOLUME{1}.nodes,VOLUME{1}.edges,.1,1e-2);
newPh = angle(result);
newPh(newPh<0) = newPh(newPh<0)+pi*2;
VOLUME{1}.ph(:,curScan) = newPh;
VOLUME{1}.ph(:,curScan) = ph;

%%% Compile MEX file for sumOfNeighbors
% mcc -ir sumOfNeighbors

%%% Test sumOfNeighbors

nodes = VOLUME{1}.nodes;
edges = VOLUME{1}.edges;
numNeighbors = nodes(4,:);
sumNeighbors = sumOfNeighbors(real(z),nodes,edges,numNeighbors);
figure(3)
plot(sumNeighbors,'.')
