function relamps = fmri_relamps(betas);
%
% relamps = fmri_relamps(betas);
%
% calculates the relative fMRI amplitude for multiple fMRI time courses,
% using the method given in Ress & Heeger, NN2002. (Dot-product w/ avg TC).
%
% betas: a 2-D or 3-D matrix of size time points x conditions x subjects,
% containing fMRI time courses for different conditions
%
% relamps: a matrix of size subjects x conditions, containing the relative
% amplitudes
%
% 10/03 ras.
nSubjs = size(betas,3);
nConds = size(betas,2);

% make all time courses have a mean of zero (avoid baseline fx)
for subj = 1:nSubjs
    offset = repmat(mean(betas(:,:,subj)),size(betas(:,:,subj),1),1);
    betas(:,:,subj) = betas(:,:,subj) - offset;
end

for cond = 1:nConds
	% calculate the overall average time course for subject
	avgTC = nanmean(betas(:,:,subj)')';

    for subj = 1:nSubjs
        relamps(subj,cond) = dot(betas(:,cond,subj),avgTC)./dot(avgTC,avgTC);
    end
end

return
