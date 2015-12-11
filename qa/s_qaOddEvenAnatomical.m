%% s_qaOddEvenAnatomical
%
% For anatomical testing, we look at the odd and even planes in various
% directions, find the points above a threshold level for the brain mask,
% and compute the slice-to-slice correlation.  When the level is low, we
% worry.
%
% For diffusion, we should use mean diffusivity as a first test
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
chdir('~/Desktop')
[plinkList,delimiter] = importdata('memprage_nifti_files.txt');

%%  This is the value we use to decide whether we are in the brain

% By setting this level, we don't use the background as part of the
% correlation calculation
maskLevel = 120;

%% Download a file from LMP's nift file list using sdmGet

nFiles = length(plinkList);
minList = zeros(1,nFiles);
fullList = cell(1,nFiles);

figure;
for nn=1:nFiles
    tic

    pLink = plinkList{nn};
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
                elseif dim == 2
                    odd = anat1.data(:,1:2:sz(3),:,ii);
                    even = anat1.data(:,2:2:sz(3),:,ii);
                elseif dim ==1
                    % Is this Axial?  Or What?
                    odd = anat1.data(1:2:sz(3),:,:,ii);
                    even = anat1.data(2:2:sz(3),:,:,ii);
                end
                odd = odd(:); even = even(:);
                keep = (odd > maskLevel); odd = odd(keep); even = even(keep);
                R = corrcoef(single(odd(:)),single(even(:)));
                thisList(dim,ii)  = R(2,1);
            end
        end
    end
    toc
    
    
    %% Maybe force display by a flag
    
    % Store for future returns
    fullList{nn} = thisList;
    minList(nn) = min(thisList(:));
    
    % Running plot for user
    plot(minList,'-o'); set(gca,'ylim',[0.7 1]);
    xlabel('File number');
    ylabel('Min r across conditions')
    % line([1 nFiles],[T T],'color','r'); grid on; drawnow
    
    % Get rid of downloaded file
    delete(sdmFile);
end

save memprage fullList minList

%% Have a look at the worst one

% nn = 153;   % Worst one
% nn = 58, 121 are both pretty low
% 74 is really bad arcs.  See what looks odd about this

nn = 64;   % Best one
pLink = plinkList{nn};
fullList{nn}
sdmFile = sdmGet(pLink,'wandell@stanford.edu','tmp.nii.gz');
anat1 = niftiRead(sdmFile);
showMontage(anat1.data(:,:,:,1));

% Just called tmp.nii.gz
% delete(sdmFile);

mrvNewGraphWin;
plot(minList,'-o');

%
bad = 'https://sni-sdm.stanford.edu/api/acquisitions/55b705089173fc362ab00639/file/9999.109235058875865466036129522252016025427_nifti.nii.gz'
for ii=1:length(plinkList)
    if isequal(bad,plinkList{ii})
        disp(ii)
    end
end

    
%%