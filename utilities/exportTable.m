function status = exportTable(table, pth);
% Write out a table to a text file.
%
% status = exportTable(table, [pth=dialog]);
% 
% table should be a cell array of strings (1D or 2D). 
% THis function was written for tables produces by the MATLAB
% anova functions.
%
% ras, 11/2007.
if notDefined('table'), error('Need an ANOVA table .'); end
if notDefined('pth'),	
	pth = mrvSelectFile('w', 'txt', 'Specify ANOVA Table file'); 
end

status = -1;

fid = fopen(pth, 'w');
if fid < 1
	error( sprintf('Couldn''t open file %s for writing.', pth) )
end

for i = 1:size(table, 1)
	for j = 1:size(table, 2)
		val = table{i,j};
		if isnumeric(val)
			fprintf(fid, '%s\t', num2str(val));
		else
			fprintf(fid, '%s\t', val);
		end
	end
	
	fprintf(fid, '\n');
end

st = fclose(fid);

if st==0  % ok flag from fclose
	status = 1;
	fprintf('Saved table as %s.\n', pth);
end

return
