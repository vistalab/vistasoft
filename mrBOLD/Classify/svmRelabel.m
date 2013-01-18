function svm = svmRelabel(svm, indices, optLabel, updateTrial) 
% svm = svmRelabel(svm, indices, optLabel, updateTrial) 
% SUPPORT VECTOR MACHINE - RELABEL 
% ---------------------------------------------------------
% Relabel/join groups in an SVM structure.
%
% INPUTS
% 	svm - Structure created by svmInit.
% 	indices - Cell array of vectors containing indices you'd like grouped. 
% 	optLabel - Cell array of strings containing names corresponding to new
%       groups created within cells. DEFAULT: Automatically combine
%       condition names.
% 	updateTrial - Whether to relabel trials to properly indicate order that
%       the trials came in (otherwise you will have duplicate trials when
%       several conditions are grouped) DEFAULT: true
%
% OUTPUTS
% 	svm - Relabeled SVM structure.
%
% USAGE
%	Any field can be grouped by specifying its name, and the indices you'd
%	like grouped.
%       svm = svmInit(...);
%		svm = svmRelabel(svm, [1 2 3]); 
%
%	In the case of group, you can designate a new label.  If you don't, one
%	will be made for you.
% 		svm = svmRelabel(svm, [2 4 6], 'evens');
%       
%   Passing in cell arrays of indices and labels allows simultaneous
%   relabeling of several sets of conditions.
%       svm = svmRelabel(svm, {[1 3 5] [2 4 6]}, {'odds' 'evens'});
%
% See also SVMINIT, SVMRUN, SVMEXPORTMAP, SVMBOOTSTRAP, SVMREMOVE,
% SVMRUNOPTIONS, SLINIT.
%
% renobowen@gmail.com [2010]
%

	if (notDefined('svm') || notDefined('indices'))
		fprintf(1, 'Too few input arguments.\n');
		return;
	end

	% Set defaults
    if (notDefined('optLabel')), optLabel = []; end
    if (notDefined('updateTrial')), updateTrial = 1; end
    
    % Normalize everything to cell array format
    if (~iscell(indices)), indices = {indices}; end
    if (~isempty(optLabel) && ~iscell(optLabel)), optLabel = {optLabel}; end
    
    indices = cellfun(@sort, indices, 'UniformOutput', false);
    
	if (isempty(optLabel))
		optLabel = cell(1,length(indices));
		for i = 1:length(indices)
			optLabel{i} = strcat(svm.grouplabel{indices{i}});
		end
	end
	svm = Relabel(svm, indices, optLabel);
	svm = RepairGroupLabels(svm, indices);
	if (updateTrial), svm = UpdateTrialField(svm); end
end

function svm = Relabel(svm, indices, optLabel)
    if (iscell(indices))
        for i = 1:length(indices)
            if (notDefined('optLabel'))
                svm = Relabel(svm, indices{i});
            else
                svm = Relabel(svm, indices{i}, optLabel{i});
            end
        end
        return;
    else
        newValue = indices(1);
        indicesToCombine = ismember(svm.group, indices);
        svm.group(indicesToCombine) = newValue;
    end
    
    if (notDefined('optLabel')), return; end
     
    svm.grouplabel{indices(1)} = optLabel;
end

function svm = UpdateTrialField(svm)
	runs = unique(svm.run)';
    for i = runs
        groups = unique(svm.group(svm.run == i))';
        for j = groups
            trials 	= find(svm.run == i & svm.group == j); 
            svm.trial(trials) = (1:length(trials))';
        end
    end
end

function svm = RepairGroupLabels(svm, indices)
   	minIndices = cellfun(@min, indices, 'UniformOutput', false);     

	removedIndices = [];
	for i = 1:length(indices)
		removedIndices = [removedIndices indices{i}(2:end)];
	end

    labelIndices = 1:length(svm.grouplabel);
    labelIndices = setdiff(labelIndices, removedIndices);
    for i = labelIndices
		newInd = find(labelIndices == i);
        svm.group(svm.group == i) = newInd;
		svm.grouplabel{newInd} = svm.grouplabel{i};
    end

    svm.grouplabel = svm.grouplabel(1:length(labelIndices));
end
