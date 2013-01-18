function tfi_hackOffSkull(normImg,fslStripImg,stripImg);
%
% tfi_hackOffSkull(normImg,fslStripImg,stripImg);
%
% Problem: there are 2 attempts to produce a skull-stripped
% image in the tfi path (one produced by fsl bet, and one
% produced by SkullStrip.tcl), and neither of them
% reliably do all the things needed.
%
% Solution: combine info from the two. This loads
% both the existing volumes, sets the norm img
% to zero wherever the fsl stripped img is zero,
% and saves the result as stripImg.
%
% This is a very crude hack designed to test the
% remaining code until Jonas updates SkullStrip.
% 
%
% ras 02/05.
[img1 mmpervox1] = loadAnalyze(normImg);
[img2 mmpervox2] = loadAnalyze(fslStripImg);
if ~isequal(mmpervox1,mmpervox2)
    error('Volumes not equal size.')
end

img1(img2==0) = 0;
saveAnalyze(img1,stripImg(1:end-4),mmpervox1);

return