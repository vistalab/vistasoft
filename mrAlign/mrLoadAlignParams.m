%mrLoadAlignParams
%
%Loads in the file 'AlignParams.mat' from the current directory.
%If the file is not found, 'VolParams.mat' is loaded, and a new
%file 'AlignParams.mat' is created.  This way, mrLoadAlignParams
%can be used to seamlessly update 'VolParams' to 'AlignParams' to
%incorporate the switch from mrLoadVol to mrAlign.

%7/28/97 gmb   Wrote it.

ipSkip = 0;
curInplane = 0;
aTheta = 0;
cTheta = 0;

qt = '''';
if check4File('AlignParams')
  load AlignParams	
else
  disp(['File ',qt,'AlignParams.mat',qt,' not found.']);
  if check4File('VolParams')
    disp(['Loading file ',qt,'VolParams.mat',qt]);
    disp(['and creating file ',qt,'AlignParams.mat',qt,'.']);
    load VolParams		    %holds curSag obXM obYM subject inplane_pix_size 
    ipThickness = 1/inplane_pix_size(3);
    mrSaveAlignParams(obXM,obYM,subject,inplane_pix_size,...
	ipThickness,ipSkip,curSag,curInplane,aTheta,cTheta);
  else
    disp(['File ',qt,'VolParams.mat',qt,' not found.']);
    disp(['No files were loaded.']);
    return
  end
end




