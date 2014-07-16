function dtiRawAverage(rawNii, rawBvecs, rawBvals)
%
% dtiRawAverage(rawNii, rawBvecs, rawBvals)
%
% HISTORY:
% 2009.09.14 RFD: wrote it.

[p,f,e2] = fileparts(rawNii);
[junk,f,e1] = fileparts(f);
bn = fullfile(p,f);
if(~exist('rawBvecs','var')||isempty(rawBvecs))
    rawBvecs = [bn '.bvecs'];
end
if(~exist('rawBvals','var')||isempty(rawBvals))
    rawBvals = [bn '.bvals'];
end


ni = niftiRead(rawNii);
bvals = dlmread(rawBvals);
bvecs = dlmread(rawBvecs);

% First collapse measurements with opposite polarity. This will also
% collapse b=0 measurements.
n = min(size(bvals,2),size(bvecs,2));
bv = [bvecs(:,1:n).*repmat(bvals(:,1:n),[3 1])];
nMeasurements = size(bv,2);
cross = cell(nMeasurements,1);
for(ii=1:nMeasurements)
    %distSame = sqrt((bv(1,:)-bv(1,ii)).^2+(bv(2,:)-bv(2,ii)).^2+(bv(3,:)-bv(3,ii)).^2);
    distOpp = sqrt((bv(1,:)+bv(1,ii)).^2+(bv(2,:)+bv(2,ii)).^2+(bv(3,:)+bv(3,ii)).^2);
    cross{ii} = [unique([ii find(distOpp<0.1)])];
end
pool = cross{1};
keep{1} = cross{1};
n = 1;
for(ii=2:nMeasurements)
    if(~any(ismember(cross{ii},pool)))
        n = n+1;
        keep{n} = cross{ii};
        pool = [pool cross{ii}];
    end
end

sz = size(ni.data);
data = zeros([sz(1:3) n]);
newBvecs = zeros(3,n);
newBvals = zeros(1,n);
for(ii=1:n)
    if(bvals(ii)>0.1)
        % geometric mean for DW data
        data(:,:,:,ii) = exp(mean(log(double(ni.data(:,:,:,keep{ii}))),4));
    else
        data(:,:,:,ii) = mean(double(ni.data(:,:,:,keep{ii})),4);
    end
    % TODO: take mean of all bvecs
    newBvecs(:,ii) = bvecs(:,keep{ii}(1));
    newBvals(:,ii) = bvals(:,keep{ii}(1));
end

% TODO: do something similar to collapse across simple repeats...

ni.fname = [bn '_avg.nii.gz'];
ni.data = single(data);
writeFileNifti(ni);
dlmwrite([bn '_avg.bvecs'],newBvecs, 'delimiter', ' ');
dlmwrite([bn '_avg.bvals'],newBvals, 'delimiter', ' ');
return;

