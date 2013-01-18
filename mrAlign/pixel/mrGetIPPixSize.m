function [inplane_pix_size] = mrGetIPPixSize()
%function [inplane_pix_size] = mrGetIPPixSize()
%
% PURPOSE: Prompt the user for the inplane anatomy pixel size
% AUTHOR:  Poirson 
% DATE:    07.16.97
% HISTORY: Based on routine by Geoff Boynton 
% NOTES:   The default values [256/260,256/260,1/4] mean that
%          26 cm of brain image are interpolated on the 256 pixels
%          in the x and y dimensions (units are pixels/mm).
%          And that 1 pixel in the inplane direction equals 4mm thickness.
%

% 04/13/00 huk and nestares -- gets defPixSize from mrSESSION now
% 07/27/00 wandell, brewer  -- added extra check for reconParams field

global mrSESSION

qt=''''; %single quote character

if    isfield(mrSESSION,'fullInplaneSize') & ...
      isfield(mrSESSION,'reconParams') & ...
      isfield(mrSESSION.reconParams(1),'FOV') & ...
      isfield(mrSESSION.reconParams(1),'sliceThickness')
  defPixSize =  [mrSESSION.fullInplaneSize(1)/ mrSESSION.reconParams(1).FOV, ...
                 mrSESSION.fullInplaneSize(2)/mrSESSION.reconParams(1).FOV, ...
                 1/mrSESSION.reconParams(1).sliceThickness];
  disp('Calculating inplane anatomy voxel size from fullInplaneSize, FOV, and sliceThickness.');
else
  defPixSize = [256/260,256/260,1/4];
  disp('mrSESSION inplane voxel size info does not exist.  Default values set; check your protocol parameters.');
end

disp('Enter size of inplane anatomy pixels/mm in x,y and z directions');
%inplane_pix_size=input('Default is [256/260,256/260,1/4]: ');
defStr = mat2str(defPixSize);
inplane_pix_size=input(['Default is: ' defStr ': ']);
%Or go the default
if isempty(inplane_pix_size)
	inplane_pix_size= defPixSize;
end

return




