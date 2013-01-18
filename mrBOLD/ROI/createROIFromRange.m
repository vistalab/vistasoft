function [view ROI] = createROIFromRange(view, range, varargin)
% createROIFromRange
%   Generates an ROI from a range of values given by the user.  Optional
%   ability to generate histogram with feedback re: data within range.
%
% Usage:
%   [view ROI] = createROIFromRange(view, range, varargin)
% 
%   View:
%       Volume/gray struct.
%
%   Range:
%       String encoding desired values.  If empty, will prompt for string.
%           FORMAT: OPAREN MINNUMBER , MAXNUMBER CPAREN
%               OPAREN - ( for exlusive, [ for inclusive
%               MINNUMBER - int/double of min, empty for no min
%               MAXNUMBER - int/double of max, empty for no max
%               CPAREN - ) for exclusive, ] for inclusive
%   
%           Examples:
%               (3, 4] - from 3 exclusive to 4 inclusive
%               [2,) - from 2 inclusive to max
%               [,-1] - from min to -1 inclusive
%
%               Note:
%                   inclusive/exclusive does not effect empty nums (always
%                   treated as 'inclusive' on the min/max value)
%               
%   Varargin Options:
%       'showhist' - Display histogram of values in range (true/false)
%           * DEFAULT false
%       'addflag' - Add ROI to view
%           * DEFAULT true
%       'roiname' - String for new name of ROI
%           * DEFAULT named by input range string
%
% Output:
%   View:
%       Volume/gray struct with ROI added
%
%   ROI:
%       ROI struct
% 
% [renobowen@gmail.com 2010]
%
    if (isempty(view.map))
        ROI = [];
        error('No parameter map loaded.');
        return;
    end
    
    if (isempty(range))
        range = inputdlg('Enter range (see help CreateROIFromRange for instructions):',...
            'Enter Range', 1, {'[,]'});
        range = range{1};
    end
    
    [isOpenInclusive num1 num2 isCloseInclusive] = ParseRange(range);
    if (isempty(isOpenInclusive))
        ROI = [];
        return;
    end
    
    curScan = view.curScan;
    
    % Defaults
    showHist = false;
    addFlag = true;
    roiname = [];
    for i = 1:2:length(varargin)
        switch lower(varargin{i})
            case {'showhist'}
                showHist = varargin{i + 1};
            case {'addflag'}
                addFlag = varargin{i + 1};
            case {'roiname'}
                roiname = varargin{i + 1};
            otherwise
                fprintf(1, 'Unrecognized option: ''%s''', varargin{i});
        end
    end
            
    if (isempty(num1)), num1 = min(view.map{curScan}); isOpenInclusive = 1; end
    if (isempty(num2)), num2 = max(view.map{curScan}); isCloseInclusive = 1; end
    
    if (isOpenInclusive)
        openInds = find(view.map{curScan} >= num1);
    else
        openInds = find(view.map{curScan} > num1);
    end
    
    if (isCloseInclusive)
        closeInds = find(view.map{curScan} <= num2);
    else
        closeInds = find(view.map{curScan} < num2);
    end
    
    inds = intersect(openInds, closeInds);
    
    coords = view.coords(:, inds);
    
    ROI.coords = coords;
    ROI.color = 'w';
    if isempty(roiname)
        ROI.name = sprintf('range%s',range);
    else
        ROI.name = roiname;
    end
    ROI.viewType = view.viewType;
    
    if (addFlag), view = addROI(view, ROI); view.ui.showROIs = -1; end
    if (showHist), ShowRangeHistogram(view.map{curScan}(inds)); end
end

function [isOpenInclusive num1 num2 isCloseInclusive] = ParseRange(range)
% [isOpenInclusive num1 num2 isCloseInclusive] = parseRange(range)
%   Parse a range statement using regular expressions, returning properly
%   digested tokens to be used in selecting the values.
%
    isCloseInclusive = 0;
    num1 = 0; num2 = 0;
    
    % Regular expressions to parse range
    number = '((-)?(\d)+(\.(\d)+)?)';
    optNumber = [number '?'];
    openParen = '(\(|\[)';
    closeParen = '(\)|\])';
    comma = '(\,)';
    whitespace = '((\s)*)';
    rangeExp = ['(?<openParen>' openParen ')' whitespace '(?<num1>' optNumber ')' ...
        whitespace comma whitespace '(?<num2>' optNumber ')' whitespace '(?<closeParen>' closeParen ')'];
    result = regexp(range, rangeExp, 'names');
    
    if (isempty(result))
        isOpenInclusive = [];
        error('Malformed range input, please see the following help text for instructions.');
        return;
    end
    
    isOpenInclusive = strcmp(result.openParen, '[');
    isCloseInclusive = strcmp(result.closeParen, ']');
    num1 = str2num(result.num1);
    num2 = str2num(result.num2);
    
end

function ShowRangeHistogram(data)
    h = figure;
    hist(data);
    axes = get(h, 'CurrentAxes');

    yLim = get(axes, 'YLim');
    yRange = yLim(2) - yLim(1);
    yPos = [(yLim(2) - yRange * .05), (yLim(2) - yRange * .1)];

    xLim = get(axes, 'XLim');
    xRange = xLim(2) - xLim(1);
    xPos = ones(1, 2) * (xLim(1) + xRange * .05);

    text(xPos(1), yPos(1), ['min: ' num2str(min(data))]);
    text(xPos(2), yPos(2), ['max: ' num2str(max(data))]);
end
    

