function  [fg, originalIDs] = dtiShuffleFibers(fg)
%Shuffles fibers in a fibergroup. 
%
%  [fg, originalIDs] = dtiShuffleFibers(fg)
%
% Randomly shuffle a group of fibers from a fibergroup;
% first reshuffle them, then pick a continuous range of indices from the
% reshuffled fiber set. 
%
%ER 03/2008 wrote it
%ER 08/2009 added output variable originalIDs
%BW It seemed broken to me in that the size of the fiber group that was
%   originally N came back as NxN. 
%
% (c) Stanford VISTA Team

% Should check argument

%A comment would be nice.
Nfibers = size(fg.fibers, 1); 

% Replaced the RandSample thing with Shuffle, which is what this routine is
% called anyway.  What was happening before returned a bad size of fibers
% (IMHO)  - BW.
shuffledOrder = Shuffle(1:Nfibers);
fg.fibers = fg.fibers(shuffledOrder);

if ~isfield(fg, 'seeds') || isempty(fg.seeds) 
    % Do nothing?
else
    fg.seeds=fg.seeds(shuffledOrder, :);
end

if ~isfield(fg, 'subgroup') || isempty(fg.subgroup)
else
    fg.subgroup=fg.subgroup(shuffledOrder);
end

originalIDs = shuffledOrder;

return
