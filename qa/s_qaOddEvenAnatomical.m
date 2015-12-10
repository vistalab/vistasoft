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

%%
T = 0.93;    % Threshold for the memprage correlation test.  This seems OK for T1

% This might be OK for diffusion, which has a larger voxel size and we are
% actually changing the direction of the gradient
% T = 0.88;


%% Download a file from LMP's nift file list using sdmGet
chdir('~/Desktop')
[A,delimiter] = importdata('memprage_nifti_files.txt');

nFiles = length(A);
minList = zeros(1,nFiles);
fullList = cell(1,nFiles);

figure;
for nn=1:nFiles
    tic

    pLink = A{nn};
    sdmFile = sdmGet(pLink,'wandell@stanford.edu');
    
    
    %% Even and Odd
    
    % For each different dimension try this.
    %
    % The multi-echo has 4 dimensions.  We need to trap that case.
    % Similarly, we need to deal with the diffusion gradients and maybe
    % multiple b-values in the future.
    %
    % I guess we should always assume that the first 3 dimensions are the
    % volume and the side conditions are the other dimensions, such as time.
    anat1 = niftiRead(sdmFile);
    sz = anat1.dim;
    thisList = zeros(3,sz(4));
    % showMontage(anat1.data);
    
    
    %% Loop on each direction and each flip angle
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
                thisList(dim,ii)  = R(2,1);
            end
        end
    end
    toc
    
    
    %% Maybe force display by a flag
    % cList
    thisMin = min(thisList(:));
    if thisMin < T
        fprintf('Minimum correlation %.3f\n',thisMin);
        %         [v,idx] = min(thisList(:));
        %         thisMin.pos = ind2sub(idx,size(thisList));
    else
        fprintf('All even/odd correlations exceed %.3f correlation\n',T);
        % thisMin.pos = [0,0];
    end
    
    % Store for future returns
    fullList{nn} = thisList;
    minList(nn) = thisMin;
    
    % Running plot for user
    plot(minList,'-o'); set(gca,'ylim',[0.7 1]);
    line([1 nFiles],[T T],'color','r'); grid on; drawnow
    
    % Get rid of downloaded file
    delete(sdmFile);
end

save memprage fullList minList

%% Have a look at the worst one

nn = 153;   % Worst one

nn = 147;   % Best one
pLink = A{nn};
sdmFile = sdmGet(pLink,'wandell@stanford.edu','tmp.nii.gz');
anat1 = niftiRead(sdmFile);
showMontage(anat1.data);

% Just called tmp.nii.gz
% delete(sdmFile);


%%