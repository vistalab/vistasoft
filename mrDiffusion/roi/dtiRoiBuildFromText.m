function roi = dtiRoiBuildFromText(fname)
%
% roi = dtiRoiBuildFromText(fname)
%
% 
%
% 2007.08.03 RFD wrote it.
%

if(~exist('fname','var')||isempty(fname))
  [f,p] = uigetfile({'*.txt','text-file';'*.*','All files'},'Select a text file of coordinates...');
  if(isnumeric(f))
	disp('User canceled.'); return;
  end
  fname = fullfile(p,f);
end

[p,roiName,e] = fileparts(fname);
coordSpace = 'MNI';
color = 'm';
coords = dlmread(fname);
if(size(coords,2)~=3)
  coords = coords';
end
if(size(coords,2)~=3)
  error('text file must be arranged as three columns.');
end
roi = dtiNewRoi(roiName, color, coords); 

outFname = fullfile(p,[roiName '.mat']);
disp(['Saving mrDiffusion roi to ' outFname '...']);
dtiWriteRoi(roi, outFname, [], coordSpace);

if(nargout==0)
    clear roi;
end
return;
