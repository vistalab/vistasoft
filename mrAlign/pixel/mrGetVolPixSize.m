function [volume_pix_size] = mrGetVolPixSize(voldr,subject)
%function [volume_pix_size] = mrGetVolPixSize(voldr,subject)
%
% PURPOSE: Prompt the user for the volume pixel size
% AUTHOR:  Poirson 
% DATE:    03.16.98
% HISTORY: Based on routine by Geoff Boynton 
% NOTES:   The default values [256/240,256/240,1/1] mean that
%          24 cm of brain image are interpolated on the 256 pixels
%          in the  x and y dimensions (units are pixels/mm).
%          And that the volume plane thickness is 1 pixel per 1 mm.
%
% 09.17.99 RFD: cleaned up the code a bit.
% 04.01.01 ARW : Shouldn't that default 1mm  be a 124/150mm?
% See if we can just read the values
if nargin<2 % new way- full path is passed in
	paramsFile = [voldr,filesep,'UnfoldParams'];
else % old method- pass two variable that must be combined (why?)
  	paramsFile = [voldr,filesep,subject,filesep,'UnfoldParams'];
end

if ~exist([paramsFile '.mat'], 'file')
  disp ([paramsFile ' not found.']);
  disp ('Please enter values.');
  disp('Enter size of volume anatomy pixels/mm in x,y and z directions');
  volume_pix_size=input('Default is [256/240,256/240,124/150]: ');

  if isempty(volume_pix_size)
    volume_pix_size=[256/240,256/240,124/150];
  end

  %Create the file 'UnfoldParams.mat' in the subject's volume anatomy directory
  estr=(['save ' paramsFile ' volume_pix_size']);
  eval(estr);
else 	% Load in the infolding parameters (volme_pix_sizes)
  estr=(['load ' paramsFile]);
  eval(estr);
  volume_pix_size = volume_pix_size;
end

return




