function mrGetUnfoldParams(voldr,subject)
%function mrGetUnfoldParams(voldr,subject)
%
%Prompts the user for information to create the file
%'UnfoldParams.mat', which is placed in the subject's
%volume anatomy directory.
%
%UnfoldParams.mat hold the variables:
%  volume_pix_size	size of volume anatomy pixels
%  volumeDataFile	location and name of volume anatomy ascii file which
%			is created by the flattening software

%6/16/96	gmb	Wrote it.
%7/24/96	gmb	removed volumeDataFile string


%Prompt the user for the volume anatomy pixel size
disp('Enter size of volume anatomy pixels/mm in x,y and z directions');
volume_pix_size=input('Default is [256/240,256/240,1]: ');

%Or go to the default
if isempty(volume_pix_size)
	volume_pix_size=[256/240,256/240,1];
end


%Create the file 'UnfoldParams.mat' in the subject's volume anatomy directory
estr=(['save ',voldr,'/',subject,'/UnfoldParams volume_pix_size']);
eval(estr);
