function [white, anatpath] = BuildWhiteVolume(hemisphere, fName)

% [white, path] = BuildWhiteVolume([hemisphere, fName]);
%
% Create a binary map of the white matter of the designated hemispheres.
% Optional input hemisphere is 0 for both [default], 1 for left, or 2 for
% right. Optional input fName allows specification of classFile name;
% default guesses file name from anatomy path.
%
% Ress, 07/05

mrGlobals

if ~exist('hemisphere', 'var') | isempty(hemisphere), hemisphere = 0; end

switch hemisphere
  case 0
    hemispheres = {'Left' 'Right'};
  case 1
    hemispheres = {'Left'};
  case 2
    hemispheres = {'Right'};
  otherwise, hemispheres = {'Left' 'Right'};
end

nHemi = length(hemispheres);

if ~exist('fName', 'var') | isempty(fName)
  if exist('vANATOMYPATH', 'var')
    [anatpath, name] = fileparts(vANATOMYPATH);
    for iH=1:nHemi
      dName = fullfile(anatpath, hemispheres{iH});
      if exist(dName, 'dir')
        fList = dir(fullfile(dName, '*.?lass'));
        if ~isempty(fList), fName{iH} = fullfile(dName, fList(1).name); end
      else
        disp(['Could not find ' hemispheres{iH} ' hemisphere class file!'])
        nHemi = nHemi - 1;
      end
    end
  end
end

if ~exist('fName', 'var') | isempty(fName)
  disp('Must provide class-file name');
  dist = [];
  return
else
  if ~iscell(fName), fName = {fName}; end
end

% Get classification volume and create binary map of white matter
for iH=1:nHemi
  class = readClassFile(fName{iH}, 0, 0);
  if exist('white', 'var')
    white = white | (class.data == class.type.white);
  else
    white = (class.data == class.type.white);
  end
end
