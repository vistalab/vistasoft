function vw = er_assignParfilesToScans(vw, whichScans, parfiles) 
% Provides dialogs for associating particular scans with par files.
%
%    er_assignParfilesToScans(vw, [scans, parfiles]);
%
% This field contains the parameter files associated with each of the
% scans. Modifies dataTYPES.scanParams so that an additional field,
% 'parfile' is added if it's not already present. 
%
% The default location for par files is:
%
% session's HOMEDIR / stim / parfiles / [parfiles here]
%
% 11/13/02 by ras
% 04/02/04 ras: if only 1 parfile selected, now assigns it 
% to all the selected scans.
% 06/06 ras: now scriptable, dialog is optional.

global dataTYPES HOMEDIR;

if notDefined('whichScans') || notDefined('parfiles')
	whichSeries = vw.curDataType;
    scanList = {dataTYPES(whichSeries).scanParams.annotation};
    for i = 1:length(scanList)
        if isempty(scanList{i}), scanList{i} = sprintf('Scan%i',i); end
    end
	[whichScans,ok] = listdlg('PromptString','Assign which scans?',...
        'ListSize',[400 600],...
        'ListString',scanList,'InitialValue',1 ,'OKString','OK');
	if ~ok,  return;  end
	
	
	pattern = fullfile(parfilesDir(vw),'*.p*');
	parList = grabfields(dir(pattern),'name');
	parList = [{'(None)'} parList];
	[sel,ok] = listdlg('PromptString','To which .par files?',...
        'ListSize',[400 600],...
       'ListString',parList,'InitialValue',1,'OKString','OK');
	if ~ok,  return;  end
	
	if length(sel)==1
        % if only one chosen, assign this parfile to all scans
        for i = 1:length(whichScans)
            parfiles{i} = parList{sel};
        end
	else
        for i = 1:length(sel)
		%     parfiles{i} = fullfile(parfilesDir,parList{sel(i)});
			parfiles{i} = parList{sel(i)};
        end
	end
end

% assign parfiles to dataTYPES struct
t = vw.curDataType;
for i = 1:length(whichScans)
    scan = whichScans(i);
    dataTYPES(t).scanParams(scan).parfile = parfiles{i};
    
    if isequal(parfiles{i},'(None)')
        dataTYPES(t).scanParams(scan).parfile = '';
    end    
end

% ensure non-assigned scans have a blank .parfile field in dataTYPES
for j = 1:length(dataTYPES)
    if ~isfield(dataTYPES(j).scanParams(end),'parfile')
        dataTYPES(j).scanParams(end).parfile = '';
    end
end

% update mrSESSION file
mrSessFile = fullfile(HOMEDIR, 'mrSESSION');
save(mrSessFile, 'dataTYPES', '-append');
disp('Updated mrSESSION with new parfile info.')

return