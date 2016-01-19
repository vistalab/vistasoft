%% s_qaOddEvenAnatomical
%
% We compute the mean diffusivity of the diffusion data set
% We compare the MD between odd and even slices.
% We write out the correlation between the mean(MD(:,even)) mean(MD(:,odd)
%
% Try it for a few cases and see how it runs.
%
% Try it for some cases that that we know to be problematic
%
% Try it for different slice orientations (axial, sagittal and coronal)
%
% LM/BW Vistasoft Team, 2015

d = '/home/wandell/data/mri';

% T = 0.93;    % Threshold for the correlation test.  This seems OK for T1

% This might be OK for diffusion, which has a larger voxel size and we are
% actually changing the direction of the gradient
T = 0.88;   

% This one looks OK
% file1 = 'meMPRAGE2.nii.gz';
% dFile = fullfile(d,file1);

% This one has visible artifacts that are not pullzed out by this method
% dFile = fullfile(d,'problems','Acq2ProblemT1');

% This is our first diffusion test
% dFile = fullfile(d,'problems','Acq7ProblemDiffusion');
% anat1 = niftiRead(dFile);

% This is a good diffusion case
dFile = fullfile(d,'Diffusion');



%% Even and Odd

% For each different dimension try this.
%
% The multi-echo has 4 dimensions.  We need to trap that case.
% Similarly, we need to deal with the diffusion gradients and maybe
% multiple b-values in the future. 
%
% I guess we should always assume that the first 3 dimensions are the
% volume and the side conditions are the other dimensions, such as time.
anat1 = niftiRead(dFile);

sz = anat1.dim;
% showMontage(anat1.data);

cList = zeros(3,sz(4));

%% Loop on each direction and each flip angle

tic
if length(sz) > 3
    for ii=1:sz(4)
        for dim = 1:3
            if dim == 3
                odd = anat1.data(:,:,1:2:sz(3),ii);
                even = anat1.data(:,:,2:2:sz(3),ii);
                R = corrcoef(single(odd(:)),single(even(:)));
            elseif dim == 2
                odd = anat1.data(:,1:2:sz(3),:,ii);
                even = anat1.data(:,2:2:sz(3),:,ii);
                R = corrcoef(single(odd(:)),single(even(:)));
            elseif dim ==1
                % Is this Axial?  Or What?
                odd = anat1.data(1:2:sz(3),:,:,ii);
                even = anat1.data(2:2:sz(3),:,:,ii);
                R = corrcoef(single(odd(:)),single(even(:)));
            end
            cList(dim,ii)  = R(2,1);
        end
    end
end
toc


% Maybe force display by a flag
% cList

if min(cList(:)) < T
    disp(cList)
    fprintf('Minimum correlation %.3f\n',min(cList(:)));
    [v,idx] = min(cList(:));
    r = ind2sub(idx,size(cList));
    fprintf('Lowest correlation at dim %d and other %d\n',r(1),r(2));
else
    fprintf('All even/odd correlations exceed %.3f correlation\n',T);
end



%%