function mrGetVolParams(voldr)
%function mrGetVolParams(voldr)
%
%Prompts the user for information to create the file
%'VolParams.mat', which is placed in the current scan directory.
%
%VolParams.mat holds the variables:
%  subject		name of subject
%  inplane_pix_size	size if inplane anatomy pixels

%6/16/96	gmb	Wrote it.
%7/28/97        gmb     With the transformation from mrLoadVol to
%                       mrAlign, 'VolParams' is now obsolete.  Code should call
%                       mrGetAlignParams instead.

disp('Warning: mrGetVolParams is obsolete, code should call mrGetAlignParams instead.');

disp('Current list of subject:');
dir(voldr);
subject = input('Subject name: ','s');
disp('');

%Prompt the user for the inplane anatomy pixel size
disp('Enter size of inplane anatomy pixels/mm in x,y and z directions');
inplane_pix_size=input('Default is [256/240,256/240,1/4]: ');

%Or go the default
if isempty(inplane_pix_size)
	inplane_pix_size=[256/240,256/240,1/4];
end


%Create the file 'VolParams.mat'
save VolParams subject inplane_pix_size

