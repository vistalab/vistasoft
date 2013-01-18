function outConMatStack=legaliseConMatRow(inConMatStack, badRowIndex)
% Makes sure that there are only two entries on any row
% Input is a cell array of connection matrices with a row 'badRow' in
% common
% badRow has more than 2 entries (say, t)
% there are x= (nchoosek([...],2) new rows that can be generated from
% badRow - each one having 2 entries.
% For each conMat in the input stack, generate x output conMats with each
% of the possible new rows.
% Last edited $Date: 2007/07/05 19:50:13 $
defaultConMat=sparse(inConMatStack{1});
badRow=defaultConMat(badRowIndex,:);
badRowVals=find(badRow);
badRowCombinations=nchoosek(badRowVals,2);
nCombinations=length(badRowCombinations);
nConMats=length(inConMatStack);
counter=1;
fprintf('Generating %d conmats',nConMats*nCombinations);
for thisConMat=1:nConMats
	for thisRowComb=1:nCombinations;
		outConMatTemp=sparse(inConMatStack{thisConMat});
		outConMatTemp(badRowIndex,:)=0;
		outConMatTemp(badRowIndex,badRowCombinations(thisRowComb,:))=1;
		outConMatStack{counter}=sparse(outConMatTemp);
		counter=counter+1;
	end
end
