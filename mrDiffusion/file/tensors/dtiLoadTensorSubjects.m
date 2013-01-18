function dtnew = dtiLoadTensorSubjects(ageCategory, fields, dt);

% DTnew = dtiLoadTensorSubjects(ageCategory, FIELDS, [DT]);
% 
% Loads normalized tensor data for all child (ageCategory = 'c') or adult
% (ageCategory = 'a') subjects.
% The type of data is specified by the list of strings FIELDS as described below.
%
% Possible fields are as follows (N is No. of subjects):
%   fa          XxYxZxN array of FA values
%   val         XxYxZx3xN array of eigenvalues
%   vec         XxYxZx3x3xN array of eigenvectors
%   dt6         XxYxZx6xN array of tensor entries
%   B0          XxYxZxN array of nB0 image values
%   seg1        XxYxZxN array of nB0_seg1 probabilities (gray matter)
%   seg2        XxYxZxN array of nB0_seg2 probabilities (white matter)
%   seg3        XxYxZxN array of nB0_seg3 probabilities (ventricle)
%   subCode     list of subject codes
%   subType     list of subject types ('d' = dyslexic, 'c' = control)
%   mmPerVox    voxel size in the normalized space
%   xform       transform matrix from Tailarach coords to image
%
% If DT is empty or is not given, then a new structure DTnew is created with
% the fields specified by FIELDS. If DT is supplied, then DTnew will include
% the fields in DT in addition to the requested fields.
%
% Example:
%   dt = dtiLoadTensorSubjects('c', {'val', 'vec'}, dt)
%
%
% HISTORY:
%   2004.01.30  ASH (armins@stanford.edu) wrote it
%   2004.02.26  ASH: added B0

% Check inputs
if ~sum(strcmp(ageCategory, {'a', 'c'})),
    fprintf('Invalid age category\n');
    return
end
if ~iscell(fields),
    fields = {fields};
end
for i = 1:length(fields),
    if ~sum(strcmp(fields{i}, {'fa', 'val', 'vec', 'dt6', 'B0', 'seg1', 'seg2', 'seg3', 'subCode', 'subType', 'mmPerVox', 'xform'})),
        fprintf('Invalid field %d\n', i);
        return
    end
end
if exist('dt'),
    dtnew = dt;
end

% Load subject codes
if strcmp(ageCategory, 'c'),
    [subjects, baseDir] = getSubjects('dc', 'c', 'dtiSubjectsCortexPaper.txt');
else
    [subjects, baseDir] = getSubjects('dc', 'a');
end
n = length(subjects);
subType = cell(1, n);
fprintf('%d subjects\n', n);

% Load fields one at a time
tic
for j = 1:length(fields),
    fprintf(['Loading ', fields{j}, '\n']);
    switch fields{j},
        case 'fa',
            for i = 1:n,
                subj = subjects{i};
                fprintf(' %d', i)
                load(fullfile(baseDir, subj, 'dti_analyses_armin', [subj, '_fa_nB0.mat']));
                FA(:,:,:,i) = fa;
            end
            dtnew.fa = FA;
            fprintf('\n')
        case {'val', 'vec'}
            for i = 1:n,
                fprintf(' %d', i)
                subj = subjects{i};
                load(fullfile(baseDir, subj, 'dti_analyses_armin', [subj, '_eig_nB0.mat']));
                VAL(:,:,:,:,i) = eigVal;
                VEC(:,:,:,:,:,i) = eigVec;
            end
            if strcmp(fields{j}, 'val'), dtnew.val = VAL;
            else dtnew.vec = VEC;
            end
            fprintf('\n')
        case 'dt6',
            for i = 1:n,
                fprintf(' %d', i)
                subj = subjects{i};
                load(fullfile(baseDir, subj, 'dti_analyses_armin', [subj, '_dt6_nB0.mat']));
                DT6(:,:,:,:,i) = dt6;
            end
            dtnew.dt6 = DT6;
            fprintf('\n')
        case 'B0',
            for i = 1:n,
                subj = subjects{i};
                nB0File = fullfile(baseDir, subj, 'dti_analyses', [subj, '_nB0.hdr']);
                [img, mmPerVox, hdr] = loadAnalyze(nB0File);
                B0(:,:,:,i) = permute(img, [2 1 3]);
            end
            dtnew.B0 = B0;
            fprintf('\n')
        case {'seg1', 'seg2', 'seg3'},
            s = str2num(fields{j}(4));
            for i = 1:n,
                fprintf(' %d', i)
                subj = subjects{i};
                nB0File = fullfile(baseDir, subj, 'dti_analyses', [subj, '_nB0_', fields{j}, '.hdr']);
                [img, mmPerVox, hdr] = loadAnalyze(nB0File);
                xform = hdr.mat; % Same for all?
                seg{s}(:,:,:,i) = permute(img, [2 1 3]);
            end
            dtnew.(fields{j}) = seg{s};
            fprintf('\n')
        case 'subCode',
            dtnew.subCode = subjects;
        case 'subType',
            for i = 1:n,
                subj = subjects{i};
                [subType(i), ageCode] = getSubjectType(subj);
            end
            dtnew.subType = subType;
        case 'mmPerVox',
            if ~exist('mmPerVox'),
                subj = subjects{1};     % Same for all?
                nB0File = fullfile(baseDir, subj, 'dti_analyses', [subj, '_nB0_seg1.hdr']);
                [img, mmPerVox, hdr] = loadAnalyze(nB0File);
            end
            dtnew.mmPerVox = mmPerVox;
        case 'xform',
            if ~exist('xform'),
                subj = subjects{1};     % Same for all?
                nB0File = fullfile(baseDir, subj, 'dti_analyses', [subj, '_nB0', '.hdr']);
                [img, mmPerVox, hdr] = loadAnalyze(nB0File);
                xform = hdr.mat;
            end
            dtnew.xform = xform(:,[2 1 3:4]);   
    end                   
end
toc
    
return
