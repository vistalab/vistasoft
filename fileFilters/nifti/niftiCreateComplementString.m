function [vectorResult] = niftiCreateComplementString(vectorString)
%
%Take the complement of the vectorString input. So, if we receive AIR, we
%want to return ASR. That is, take the complement of each input with
%respect to the "correct" RPS format.

vectorResult = vectorString;

searchStringMap = containers.Map;

searchStringMap('L') = 'R';
searchStringMap('A') = 'P';
searchStringMap('I') = 'S';


for i = 1:numel(vectorResult)
    if searchStringMap.isKey(vectorResult(i))
        %We need to flip it!
        vectorResult(i) = searchStringMap(vectorResult(i));
    end %if    
end %for

return