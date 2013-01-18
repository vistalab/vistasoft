function fgsub=dtiSubsetFiberGroup(fg, range)

%Create a new fiber group that contains a subset of fibers (range) of the
%superfibergroup FG.
%E.g., fgsub=dtiSubsetFiberGroup(fg, [1:100 45:500])
%ER 2007 SCSNL 

fgsub=fg; 

fgsub.fibers=fg.fibers(range);