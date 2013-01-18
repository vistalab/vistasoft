function  mrSaveAlignParams(obXM,obYM,subject,inplane_pix_size,ipThickness,ipSkip,curSag,curInplane,aTheta,cTheta)
%NAME:    mrSaveAlignParams(obXM,obYM,subject,inplane_pix_size,ipThickness,ipSkip,curSag,curInplane,aTheta,cTheta)
%AUTHOR:  Poirson
%DATE:	  08.09.96
%PURPOSE: Save all the information about the inplane alignment,
%	  so you could reconstruct the mockSS planes if you wanted.
%HISTORY: 07.28.97 ABP -- Removed 'volume_pix_size' after
% discussion with Geoff.

%NOTES:
%

save AlignParams subject inplane_pix_size obXM obYM ipThickness ipSkip curSag curInplane aTheta cTheta

disp('Finished saving AlignParams.');

return;
