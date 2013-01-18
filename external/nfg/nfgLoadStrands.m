function [fg,nfg_info] = nfgLoadStrands(dirname)
%Load strands from numerical fiber generator (NFG).
%
%   [fg,nfg_info] = nfgLoadStrands(dirname)
%
% AUTHORS:
% 2009.08.05 : AJS wrote it.
%
% NOTES: 

% Use NFG function to load strands
[strand_collection, isotropic_regions] = load_strands(dirname);
% Create output fiber group
fg = dtiNewFiberGroup;
for ll=1:size(strand_collection,1)
    % Strip off first and last points from strand
    strand = strand_collection{ll,1}';
    fg.fibers{ll} = strand(:,2:end-1);
end
% Collect remaining strand information to return
nfg_info.strandID = cell2mat(strand_collection(:,2));
nfg_info.radius = cell2mat(strand_collection(:,3));
nfg_info.bundleID = cell2mat(strand_collection(:,4));
%nfg_info = strand_collection(:,2:end);
%fields = {'strandID','radius','bundleID'};
%nfg_info = cell2struct(nfg_info, fields, 2);

return;

function [strand_collection, isotropic_regions] = load_strands(dirname)
%  function strand_collection = load_strands(dirname)
% 
%   load_strand_collection.m
%   Numerical Fibre Generator
% 
%   Created by Tom Close on 19/02/08.
%   Copyright 2008 Tom Close.
%   Distributed under the GNU General Public Licence.
% 
% 
% 
%   This file is part of 'Numerical Fibre Generator'.
% 
%   'Numerical Fibre Generator' is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   'Numerical Fibre Generator' is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with 'Numerical Fibre Generator'.  If not, see <http://www.gnu.org/licenses/>
% 
% 
% 

	num_strands = 0;
	isotropic_regions = [];
	files = dir(dirname)'; %'
	if (size(files) == [1,0]) 
		error(['Could not load any strands from directory ' dirname ]);
    end
	for file = files
		if (~file.isdir)
			delimeters = [strfind(file.name, '_') strfind(file.name, '-') strfind(file.name, '.txt' )];
			if (length(delimeters) == 4 && strmatch('strand', file.name))
				num_strands = num_strands + 1;
				strand_collection{num_strands, 1} = load([dirname filesep file.name]);
				strand_collection{num_strands, 2} = str2num(file.name(delimeters(1) + 1 :delimeters(2) -1 ));
				strand_collection{num_strands, 3} = str2num(file.name(delimeters(3) + 2 :delimeters(4) -1 ));
				strand_collection{num_strands, 4} = str2num(file.name(delimeters(2) + 1 :delimeters(3) -1 ));

            end
			if (strcmp(file.name, 'isotropic_regions.txt'))
				isotropic_regions = load([dirname filesep file.name]);
            end	
        end
	end
return;