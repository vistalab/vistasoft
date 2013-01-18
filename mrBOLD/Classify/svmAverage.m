function svm = svmAverage(svm, measure, indices, optLabel)
	% svmAverage
	%	Average across the specified measure and relabel.
	%
	%	Usage:
	%		svm = svmAverage(svm, 'group', [2 4 6], 'evens');
    %       svm = svmAverage(svm, 'trial', [1 2]);
	%	
	%	renobowen@gmail.com [2010]
	%
	if (~exist('svm', 'var') || ~exist('measure', 'var') || ~exist('indices', 'var'))
		fprintf(1, 'Too few input arguments.\n');
		return;
	end
	
	if (~exist('optLabel', 'var'))
		optLabel = [];
	end

    levels = {'trial', 'group', 'run'};
	svm = FlagOperands(svm, measure, indices, optLabel, levels);
	svm = Average(svm, levels);
	
end

function svm = FlagOperands(svm, measure, indices, optLabel, levels)
	
	mapIndices = ismember(svm.(measure), indices);
	for i = ((cellfind(levels, measure) + 1):length(levels))
		mapsTo	= unique(svm.(levels{i})(mapIndices))';
		if (length(mapsTo) ~= 1)
			fprintf(1,'These span over > 1 %s, average over %s too? [0 = No, 1 = Yes]\n', levels{i}, levels{i});
			resp = input('');
			if (resp == 1)
				svm = svmRelabel(svm, levels{i}, mapsTo, 'updateTrial', 0);
			else
				fprintf(1,'Averaging will be performed within each %s.\n\n', levels{i});
			end	
		end
	end
    svm 	= svmRelabel(svm, measure, indices, 'newlabel', optLabel, 'updateTrial', 0);

end

function svm = Average(svm, levels)
	% svmAverage
	% 	Wrapper for recursive averaging function, used
	% 	to average over redundancies in svm.data.
	%
	%	For example, if group 1 has two trial 1s, this
	% 	must be a result of the relabeling procedure
	% 	and so we will take the average of these.
	%
	% renobowen@gmail.com [2010]

    % Trials are a subset of groups, groups are a subset of runs
	% Levels thus defines the order of recursion
 
    nsvm.data 	= [];
	nsvm.run 	= [];
	nsvm.group 	= [];
	nsvm.trial 	= [];

	
	mask 		= logical(1:size(svm.data, 1))';
    mask        = ismember(svm.group, [2]);
    [nsvm tsz] 	= RecursiveAverage(svm, nsvm, mask, levels, length(levels));
	
	svm.run 	= nsvm.run;
	svm.data 	= nsvm.data;
	svm.group 	= nsvm.group;
	svm.trial 	= nsvm.trial;

end

function [nsvm sz] = RecursiveAverage(svm, nsvm, mask, levels, level)
	if (level == 0)
		data = mean(svm.data(mask, :), 1);
		nsvm.data = [nsvm.data; data];
		sz = 1;
		return;
	end
		
	field = levels{level};
	sz = 0;
	indices = unique(svm.(field)(mask))';
	for i = indices 
		nmask = mask & svm.(field) == i;
		[nsvm tsz] = RecursiveAverage(svm, nsvm, nmask, levels, level - 1); 
		nsvm.(field) = [nsvm.(field); i*ones(tsz, 1)];
		sz = sz + tsz;
    end
end

function IterativeAverage()
    




end
