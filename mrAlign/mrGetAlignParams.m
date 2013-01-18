function mrGetAlignParams(voldr)
%function mrGetAlignParams(voldr)
%
%Prompts the user for information to create the file
%'AlignParams.mat', which is placed in the current scan directory.
%

%7/28/87  gmb  Wrote this function which calles abp and spg's
%              ' mrGetSubject' and ' mrGetIPPixSize'

%Some default values
ipThickness = -99;		% inplanes thickness (mm)
ipSkip = -99;			% amount of space skipped between inplane (mm)
curSag = -99;			% sagittal slice currently displaying
curInplane = 0;
cTheta = 0;                     % default rotation angles
aTheta = 0;
obXM = [];			% Coordinates of user set inplane slices
obYM = [];

[subject] = mrGetSubject(voldr); 	
[inplane_pix_size] = mrGetIPPixSize;

% Save out 'AlignParams.mat'
mrSaveAlignParams(obXM,obYM,subject,...
    inplane_pix_size,...
    ipThickness,ipSkip,curSag,curInplane,aTheta,cTheta);




