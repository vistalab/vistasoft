function fsl_autoRemixMLRByICA(view,scanNum, nCycles,tHold)
% fsl_autoRemixMLRByICA(view,scanNum, nCycles,tHold)
% Looks thought ICA components and examines the time series and 
% power spectra.
% Automatically rejects components that have significant peaks
% outside the stimulus frequency.
% Significant? Hmm. This is trial and error but
% I think a coherence level of the highest peak 
% of somewhere around 0.05 to 0.2 is rejectable.
% Based on btlee's (btlee@ski.org) remixByICA routine. 
% TODO: We should run the mixture model and pay attention to the 
% eigenspectum: There's no point in dealing with those tiny components
% that explain only 0.0001% of the variance. Instead, we should be smarter
% about the big ones. Smarter how? 
% AUTHOR: ARW 121604: 
% $Author: wade $
% NOTES : Very much in Beta at the moment. 
%  see also : fsl_melodicMLR, fsl_motionCorrectMLR
% You must have run fsl_melodicMLR beforehand...
% Think this will work for event-related stuff as well . Maybe even better.
% It will find and detect large peaks due to systematic noise....

mrGlobals;
switch nargin,
    case {0, 1, 2},
        eval(['help fsl_autoRemixMLRByICA'])
        return;
end
 
fslBase='/raid/MRI/toolbox/FSL/fsl';
if (ispref('VISTA','fslBase'))
   disp('Setting fslBase to the one specified in the VISTA matlab preferences:');
   fslBase=getpref('VISTA','fslBase');
   disp(fslBase);
end
fslPath=fullfile(fslBase,'bin'); % This is where FSL lives

% First look for the appropriate files. We need a 'melodic_IC' , 'mask' and
% 'melodic_mix' file
% If the data have been motion corrected, there will also be a _mcf
% extension .
filebase=[pwd,filesep,'Inplane',filesep,'Original',filesep,'TSeries',filesep,'Scan',int2str(scanNum),filesep,'Analyze',filesep];

if (exist([filebase,'data_mcf.hdr'],'file'))
    origData=[filebase,'data_mcf'];
    outData=[filebase,'data_mcf_remixed']
else
    origData=[filebase,'data']
    outData=[filebase,'data_remixed']
end

% Get the base of the ica. 
icaFileBase = [filebase,filesep, 'ica',filesep]

%=== load melodic results for further analysis

clear dims scales bpp endian % to avoid confusion with those from IC file

ICfname = [icaFileBase, 'melodic_IC.img'];
if (~exist(ICfname,'file'))
    disp('No melodic_IC file found for this scan- did you run melodic?');
    return;
end

[dim, vox, scale, type, off, orig, desc] = fslHread(ICfname);
[img, dims, scales, bpp, endian] = read_avw(ICfname);
dims=size(img);
disp(dims)

dims=size(img);
disp(dims);

switch type
    case 2, dtype = 'uint8';
    case 4, dtype = 'int16';
    case 16, dtype = 'float';
    otherwise, disp(['unknown data type in ' ICfname]); return
end

if (~exist([icaFileBase, 'melodic_mix'],'file'))
    disp('No melodic_mix file found - did you run melodic?');
    return;
end

load([icaFileBase, 'melodic_mix']);
disp([icaFileBase, 'melodic_mix is loaded for selection']);

acceptComponents=ones(dims(4),1); % Set to 0 to reject
coh=ones(size(acceptComponents));
figure(99);

for i=1:dims(4) % This is the number of ICA components
subplot(dims(4),1,i);

    FT=(abs(fft(melodic_mix(:,i))));
      FT=FT(1:(fix(length(FT)/2)));
    plot(FT);

      %Compute coherence of biggest peak.
      % If there are two peaks, take the first one
      [peakHeight,peakPos]=max(FT(:));
      if length(peakHeight)>1
          peakHeight=peakHeight(1);
          peakPos=peakPos(1);
      end
      if(peakPos~=(nCycles+1))
      peakCoh=peakHeight/sqrt(sum(FT(:)).^2);
      coh(i)=peakCoh;
      if (peakCoh>tHold)
          acceptComponents(i)=0;
          fprintf('\nRejecting component %d with off-frequency peak coh %d',i,coh(i));
      end % end if coh
  end % end if no nCycles 
end % next i

% Do the denoising by calling melodic again with the --filter flag set
            
componentsToRemove=find(~acceptComponents);

shellCmd=[fslPath,filesep,'melodic -i ',origData,' -o ',outData,' -v --mix=',[icaFileBase,'melodic_mix'],' --filter="',int2str(componentsToRemove'),'"'];
disp('');

disp(shellCmd);
tic;
system(shellCmd);
toc;
    
