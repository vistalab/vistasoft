function h = plotTable(table, varargin);
% h = plotTable(table, ['property', val]): display a text
% table in a set of axes.
%
% Can pass in pairs of properties and values for the text. 
% Returns an array of handles to the text.
%
% Note this is very primitive.
%
% 08/04 ras.
h = [];

nrows = size(table,1);
ncols = size(table,2);

% ensure table is a cell-of-strings
for row = 1:nrows
    for col = 1:ncols
        if ~ischar(table{row,col})
            table{row,col} = num2str(table{row,col});
        end
    end
end       

% count the text width of each cell, get column 
% width
for col = 1:ncols
    for row = 1:nrows
        sz(row,col) = length(table(row,col));
    end
    
    width(1,col) = max(sz(:,col))+4;
end
xpos = cumsum(width);

% set axes
cla;
AX = [1 sum(width)+3 1 nrows+3];
axis(AX); axis off
set(gca,'XTick',[],'YTick',[],'Box','on');

% plot the text
for row = 1:nrows
    for col = 1:ncols
        X = xpos(col)-2;
        Y = nrows-row+2;
        if row==1
            h(end+1) = text(X,Y,table{row,col},'FontSize',10);        
        elseif col==1
            h(end+1) = text(X,Y,table{row,col},'FontSize',8,'FontWeight','bold');            
        else
            h(end+1) = text(X,Y,table{row,col},'FontSize',8);        
        end
            
    end
end

% apply optional text properties
if length(varargin)>1
    for j = 2:2:length(varargin)
        set(h, varargin{j-1}, varargin{j});
    end
end


return
