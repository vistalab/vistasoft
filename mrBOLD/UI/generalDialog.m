function [resp, ok] = generalDialog(dlg, title, figPos)
%
% [resp, ok] = generalDialog(dlg, [title], [figPos])
%
% Create a dialog w/ UI control text, edit, popup,
% checkbox, or listbox menus for different items,
% and return a struct with the user-selected values
% in the appropriate fields. A replacement for generaldlg.
%
% INPUTS:
% dlg: struct array w/ the following fields:
%   string: text to describe what item you want to set
%   fieldName: name of field in resp
%   list: For popup menus and listboxes, a cell array of strings
%         containing a list of possible options
%   style: What type of uicontrol should be: any of 
%          'text', 'edit', 'popup', 'listbox', 'checkbox', 'filename', 'number'.
%
%			For edit fields, can also make the edit field multiline by adding 
%			a number after 'edit'-- e.g., 'edit5' will make it a 5-line edit 
%			field. This can be useful for editing long text fields. 
%
%			The special 'filename' style creates an edit field for specifying 
%			file names, with a 'Browse' button to the right of the field to 
%			navigate to a file. By default the 'browse' button
%			will use UIGETFILE, set the style to 'filenamew' ('write') 
%			to use UIPUTFILE instead.
%			The 'number' option produces an edit field, but the results of
%			this field are converted from character to numeric using
%			STR2NUM at the end.
%
%			The special 'dirname' style creates an edit field for specifying 
%			directory names, with a 'Browse' button to the right of the field to 
%			navigate to a file. Otherwise like 'filename'.
%
%			For listboxes, the size of the listbox in the dialog will match
%			as many lines as there are items in the list, up to around 12 items
%			depending on the OS. You can manually specify the size of the
%			lisbtbox by adding a number after 'listbox' -- e.g., 'listbox4'
%			will set a 4-line size. (Though the exact size is sometimes
%			larger than 4 lines on some OSes.)
%
%   value: Default value for the control. For listbox and popups,
%          this can be a string specifying the name of the 
%          selected item, or a numeric index into the list;
%          for text and edit controls, this should be a string;
%          for checkbox, this can be a 1 or 0 (checked or not).
%
%  All other fields in dlg are ignored.
%  Each entry in the dlg reflects one item the
% user should select -- e.g., the name, age, and sex of a
% person (which might be described by two edit fields and a
% popup menu).
%
% title: title text for dialog figure. 
%
% figPos: [xcorner ycorner xwidth yheight] position of the figure, or
% 'center' to center the dialog onscreen. If omitted, guesses a reasonable
% value.
%
%
% OUTPUTS:
% resp is a struct with one field for each item. The
% name is determined by each item's 'fieldName' field in
% the dlg. Edit and text items return strings (text 
% items are not changed by the user); checkboxes return a 
% 1 or 0, depending on if the checkbox is selected or not;
% popups return a string containing the name or the 
% selected item; listbox returns a cell containing the 
% names of all selected items (multiple selection is allowed).
%
% Example:
% dlg(1).style = 'edit';
% dlg(1).string = 'Name of your chicken:';
% dlg(1).value = 'Ralph';
% dlg(1).fieldName = 'chickenName';
% 
% dlg(2).style = 'checkbox';
% dlg(2).string = 'neutered?';
% dlg(2).value = 1;
% dlg(2).fieldName = 'catNeuteredFlag';
% 
% dlg(3).style = 'popup';
% dlg(3).string = 'sex?';
% dlg(3).list = {'Male' 'Female' 'Neutered'};
% dlg(3).value = 'Male';
% dlg(3).fieldName = 'chickenSexFlag';
% 
% dlg(4).style = 'number';
% dlg(4).string = 'IQ:';
% dlg(4).value = 100.34;
% dlg(4).fieldName = 'catIQ';
% 
% dlg(5).style = 'listbox';
% dlg(5).string = 'Favorite toy?';
% dlg(5).list = {'grocery bag' 'catnip' 'rubber ball'};
% dlg(5).value = 'catnip';
% dlg(5).fieldName = 'catToy';
% 
% resp = generalDialog(dlg)
%
% ras, started 04/08/05. In progress.
% ras, 05/05: working nicely.
% ras, 06/05: listbox now accepts multiple selection.
% ras, 06/30/05: imported into mrVista 2.0 Test repository.
% ras, 11/08/06: fixed listbox display bug.
% ras, 02/20/07: added filename style, mutiple edit lines. Also renamed
% 'uiStruct' and 'outStruct' to 'dlg' and 'resp', for brevity.
% ras, 05/16/08: added 'number' style.
if notDefined('title'),    title = 'mrVista';         end

resp = [];
ok = 0;

%%%%%%%%%%%%%%
% Parameters %
%%%%%%%%%%%%%%
nItems = length(dlg);
font = 'Helvetica';
if isunix, fontsz = 10; else, fontsz = 9; end
figColor = [.9 .9 .9]; % background color for figure

% count the # of vertical lines in the dialog for each item
nLines = 0;
for i = 1:nItems
	switch lower( dlg(i).style(1:4) )
		case 'list'
			% listbox, add as many lines as list entries (up to a point)
			% ...but also let the user specify the # lines in the style
			% name (e.g., 'listbox10').
			if length(dlg(i).style) > 7
				% empirically, we seem to have to divide the number by 2 --
				% has something to do w/ smaller font sizes for the list
				dlg(i).nLines = str2num(dlg(i).style(8:end)) / 2;
			else
				dlg(i).nLines = min(length(dlg(i).list), 6);
			end

		case {'edit' 'number'}
			% edit field, allow multi-line specification
			if length(dlg(i).style) > 4
				dlg(i).nLines = str2num(dlg(i).style(5:end));
			else
				dlg(i).nLines = 1;
			end
		case 'text'
			% allow string arrays with many lines			
			dlg(i).nLines = max(1, size(dlg(i).value, 1));	
		case 'file' % check for a read/write flag
			dlg(i).nLines = 1;
			if length(dlg(i).style) > 8 & lower(dlg(i).style(9))=='w'
				dlg(i).readWrite = 'w';
			else
				dlg(i).readWrite = 'r';
			end
		otherwise
			dlg(i).nLines = 1;		
	end	
end
nLines = sum([dlg.nLines]);

% make all style fields lowercase, use ok keywords
for i = 1:nItems
    dlg(i).style = lower(dlg(i).style);
    switch dlg(i).style(1:3),
        case 'tex', dlg(i).style = 'text';
        case 'edi', dlg(i).style = 'edit';
        case 'num', dlg(i).style = 'number'; 		
        case 'pop', dlg(i).style = 'popup';
        case 'lis', dlg(i).style = 'listbox';
        case 'che', dlg(i).style = 'checkbox';
		case 'fil', dlg(i).style = 'filename';
		case 'dir', dlg(i).style = 'dirname';
        otherwise, error('Uknown dlg style')
    end
end

% add 2 lines for 'Ok','Cancel' buttons plus spacers
nLines = nLines + 2;


if notDefined('figPos')  |  isequal(figPos, 'center')
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Figure out how large the figure should            %
	% be, based on how many lines need to be displayed: %
	% (all controls except listboxes will use 1 line,   %
	% listboxes will use as many as there are options   %
	% in the list.)                                     %
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	
	if notDefined('figPos'), figPos = [];   end
	
	% now figure out a good height, normalized to the screen
	figHeight = .03 * nLines;
	figHeight = min(figHeight,.8); % Don't get too big
	
	% if there's an existing figure, we'll set the dialog
	% to be centered in that window; otherwise, we'll
	% choose a reasonable start location
	if isempty(get(0,'CurrentFigure')) | isequal(figPos, 'center')
        % center onscreen
        figWidth = 0.6;
        corner = [0.2 0.5-(figHeight/2)];
	else
        % base position of dialog on current figure
		% (guessing that this is a dialog relevant to that figure)
        set(gcf,'Units','Normalized');
        ref = get(gcf,'Position');
        figWidth = 0.75 * ref(3);
        corner(1) = ref(1) + 0.125*ref(3); % roughly center in fig
        corner(2) = ref(2) + ref(3)/2 - figHeight/2;
	end
        
	figPos = [corner figWidth figHeight];
end

% figure a size for the height of each
% item -- shouldn't be too high:
height = 1/nLines;

% initial bottom line for controls (except listbox, which is complicated)
bottom = 1-height; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Open the Figure          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hfig = figure('Name',title,...
    'Units','Normalized',...
    'Position',figPos,...
    'NumberTitle','off',...
    'Color',figColor);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make controls for each item %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:nItems
    % (Note, all units are normalized to figure size)

    % Make a text label describing the item:
    if ismember(dlg(i).style, {'edit' 'number' 'listbox' 'popup' 'text' 'filename' 'dirname'})
        textPos = [.1 bottom .4 height];
        uicontrol('Style','text','String',dlg(i).string,...
            'ForegroundColor','k','BackgroundColor',figColor,...
            'FontSize',fontsz,'FontName',font,'FontAngle','normal',...
            'FontWeight','bold','HorizontalAlignment','left',...
            'Units','Normalized','Position',textPos);                
    end

    % determine item control position
	n = dlg(i).nLines;
	itemPos = [.5 bottom-(n-1)*height .4 (n*height)];
    bottom = bottom - itemPos(4); % move bottom of next control down

    % make a control for the item value
    switch dlg(i).style
        case 'text',
            h(i) = uicontrol('Style', 'text', 'String', dlg(i).value,...
                'ForegroundColor', 'k', 'BackgroundColor',figColor,...
                'FontSize', fontsz, 'FontName', font,...
				'Min', 1, 'Max', dlg(i).nLines, ...
                'Units', 'Normalized', 'Position', itemPos);

        case {'edit' 'number'},
			if isnumeric(dlg(i).value), str = num2str(dlg(i).value); 
			else,						str = dlg(i).value;
			end
			str = singleLineString(str);
			
            h(i) = uicontrol('Style', 'edit', 'String', str,...
                'ForegroundColor', 'k', 'BackgroundColor', figColor,...
				'HorizontalAlignment', 'left', ...
                'FontSize', fontsz, 'FontName', font,...
				'Min', 1, 'Max', dlg(i).nLines, ...
                'Units', 'Normalized', 'Position', itemPos);

        case 'checkbox'
            h(i) = uicontrol('Style', 'checkbox', 'String', dlg(i).string,...
                'ForegroundColor', 'k', 'BackgroundColor', figColor,...
                'FontSize', fontsz, 'FontName', font, 'FontAngle', 'italic',...
                'FontWeight', 'bold', 'Value', dlg(i).value,...
                'Units', 'Normalized', 'Position', itemPos);

        case 'listbox'
            if ischar(dlg(i).value)
                % find character default value in list of options
                val = cellfind(dlg(i).list,dlg(i).value);
            else
                % numeric default value--index into list
                val = dlg(i).value;
            end
            h(i) = uicontrol('Style','listbox','String',dlg(i).list,...
                'ForegroundColor','k','BackgroundColor',figColor,...
                'FontSize',fontsz,'FontName',font,...
                'Value',val,'Max',4,'Min',1,...
                'Units','Normalized','Position',itemPos);

        case 'popup'
            if ischar(dlg(i).value)
                % find character default value in list of options
                val = cellfind(dlg(i).list, dlg(i).value);
            else
                % numeric default value--index into list
                val = dlg(i).value;
            end
            if isempty(val), val = 1;   end
            if val < 1, val = 1; end
            if val > length(dlg(i).list), val = length(dlg(i).list); end            
            h(i) = uicontrol('Style','popupmenu','String',dlg(i).list,...
                'ForegroundColor','k','BackgroundColor',figColor,...
                'FontSize',fontsz,'FontName',font,...
                'Value',val,...
                'Units','Normalized','Position',itemPos);
			
		case 'filename'
            h(i) = uicontrol('Style', 'edit', 'String', dlg(i).value, ...
                'ForegroundColor', 'k', 'BackgroundColor', figColor, ...
                'FontSize', fontsz, 'FontName', font, ...
                'Units', 'Normalized', 'Position', itemPos);
			
			% also add the browse button
			buttonPos = itemPos + [.4 0 -.3 0];
			if dlg(i).readWrite=='r'
				cb = ['[f p] = uigetfile(''*.*'', ''Select a file...''); ' ...
					  'set(get(gcbo,''UserData''),''String'',fullfile(p,f)); '];
			else
				cb = ['[f p] = uiputfile(''*.*'', ''Select a file...''); ' ...
					  'set(get(gcbo,''UserData''),''String'',fullfile(p,f)); '];

			end
			uicontrol('Style', 'pushbutton', 'String', 'Browse', ...
				'ForegroundColor', 'w', 'BackgroundColor', [.5 .5 .6], ...
				'FontSize', fontsz, 'FontName', font, ...
				'Callback', cb, 'UserData', h(i), ...
				'Units', 'normalized', 'Position', buttonPos);
			
		case 'dirname'
            h(i) = uicontrol('Style', 'edit', 'String', dlg(i).value, ...
                'ForegroundColor', 'k', 'BackgroundColor', figColor, ...
                'FontSize', fontsz, 'FontName', font, ...
                'Units', 'Normalized', 'Position', itemPos);
			
			% also add the browse button
			buttonPos = itemPos + [.4 0 -.3 0];
			if dlg(i).readWrite=='r'
				cb = ['p = uigetdir(''*.*'', ''Select a directory...''); ' ...
					  'set(get(gcbo,''UserData''),''String'',p); '];
			else
				cb = ['p = uigetdir(''*.*'', ''Select a directory...''); ' ...
					  'set(get(gcbo,''UserData''),''String'', p); '];

			end
			uicontrol('Style', 'pushbutton', 'String', 'Browse', ...
				'ForegroundColor', 'w', 'BackgroundColor', [.5 .5 .6], ...
				'FontSize', fontsz, 'FontName', font, ...
				'Callback', cb, 'UserData', h(i), ...
				'Units', 'normalized', 'Position', buttonPos);

            
        otherwise,
            warning('generalDialog: invalid style specified...')
            dlg(i)
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%
% Add OK/Cancel Buttons %
%%%%%%%%%%%%%%%%%%%%%%%%%
% OK button
uicontrol('Style','pushbutton','String','OK',...
    'ForegroundColor','k','BackgroundColor',[0 .7 0],...
    'ForegroundColor','w',...
    'FontSize',fontsz,'FontName',font,...
    'Callback','uiresume;','Tag','OK',...
    'Units','Normalized','Position',[.04 height/2 .2 height]);
% Cancel button
uicontrol('Style','pushbutton','String','Cancel',...
    'ForegroundColor','k','BackgroundColor',[.7 0 0],...
    'FontSize',fontsz,'FontName',font,...
    'Callback','uiresume;','Tag','Cancel',...
    'Units','Normalized','Position',[.76 height/2 .2 height]);

response = '';

figOffscreenCheck(hfig);

% wait for user to select values
% wait for a 'uiresume' callback from OK/Cancel
uiwait;

%determine which button was hit.
response = get(gco,'Tag');

% parse the response
if ~isequal(response,'OK')
    % exit quietly
    close(hfig);
    return
else
    ok = 1; % we got a response, will parse below
end

% if we got here, we should be able to proceed
for i = 1:length(h)
    field = dlg(i).fieldName;
    switch dlg(i).style
        case {'text' 'edit' 'filename' 'dirname'},
				resp.(field) = get(h(i), 'String');
				if dlg(i).nLines > 1
					resp.(field) = singleLineString(resp.(field));
				end
		case 'number',
			resp.(field) = str2num( get(h(i), 'String') );
        case 'checkbox', 
			resp.(field) = get(h(i),'Value');
		case 'listbox',
			resp.(field) = dlg(i).list(get(h(i), 'Value'));
        case 'popup',
            resp.(field) = dlg(i).list{get(h(i), 'Value')};
    end
end

% close the figure
close(hfig);


return
% /-------------------------------------------------------------/ %



% /-------------------------------------------------------------/ %
function newStr = singleLineString(str);
% returns a string array that's one line (row), rather than a multi-line
% matrix. The issue with the multi-line matrix is that they get padded with
% spaces (char(32)), which can cause a string to "grow" gaps in it. For
% instance, if you run a generalDialog with a muti-line edit, get the user
% input, then re-run the dialog on the user input, line breaks will have
% many spaces between them, which grow the more often you call the
% function.
if size(str, 1) <= 1
	newStr = str; 
	return
end
newStr = '';
for i = 1:size(str, 1)
	newStr = [newStr sprintf('\n') strtrim(str(i,:))];
end
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%debug
dlg(1).style = 'edit';
dlg(1).string = 'Name of your cat:';
dlg(1).value = 'Ralph';
dlg(1).fieldName = 'catName';

dlg(2).style = 'checkbox';
dlg(2).string = 'neutered?';
dlg(2).value = 1;
dlg(2).fieldName = 'neuteredFlag';

dlg(3).style = 'popup';
dlg(3).string = 'sex?';
dlg(3).list = {'Male' 'Female' 'Neutered'};
dlg(3).value = 'Male';
dlg(3).fieldName = 'sexFlag';

dlg(4).style = 'edit5';
dlg(4).string = 'Favorite tunes?';
dlg(4).value = strvcat('Carmina Burana', 'Enter Sandman');
dlg(4).fieldName = 'catName';

dlg(5).style = 'filename';
dlg(5).string = 'Path to mp3 files?';
dlg(5).value = '';
dlg(5).fieldName = 'catMP3Path';

dlg(6).style = 'number';
dlg(6).string = 'IQ:';
dlg(6).value = 100.34;
dlg(6).fieldName = 'catIQ';

dlg(7).style = 'listbox';
dlg(7).string = 'Favorite toy?';
dlg(7).list = {'grocery bag' 'catnip' 'rubber ball'};
dlg(7).value = 'catnip';
dlg(7).fieldName = 'catToy';

resp = generalDialog(dlg, 'My Cat''s Name is Mittens')

