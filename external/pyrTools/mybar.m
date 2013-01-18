function h=mybar(f,s,xstr,ystr,col,lineWidth,w,we)
%
% mybar(f,[s],[xstr],[ystr],[color],[lineWidth],[barwidth],[errorbarwidth])
%
%  Draws a bar graph with heights determined by f
%  and error-bars determined by s.
%
%  if input matrices are 2d, the ROWS are plotted as
%  separate sub-bars in different colors.
%
%  xlabels set to 'xstr' (columns)
%  legend set to 'ystr' (rows)
%
%  color is a string of colors, one for each subbar
%  (default is 'brgmyc')
%
%  lineWidth (default 2)
%
%  barwidth (default 0.65)
%  errorbarWidth (default 0.3)
%
%  Example:
%    f = rand(5,1)+1;
%    s = rand(5,1)/2;
%    xstr = str2mat('one','two','three','four','five');
%    ystr = '';
%    mybar(f,s,xstr,ystr,'g');
%  7/11/95  gmb Wrote it.
%  4/11/96  gmb Revised it to plot 2d data sets
%  11/19/97 gmb Converted it to Matlab version 5.0
%  12/30/97 djh Fixed bug in xlabels, for some reason it was
%               putting the 1st label under the 2nd bar, and so on.
%  1/24/97  djh Added lineWidth as optional input arg
%  3/15/01  dbr Made legend size allocation a bit more intelligent.
%
%  05/2004  arw Modified so that if you pass in a list of colors for a
%  single data vector, it applies those colors to the individual bars.
%           EXAMPLE:
%          a=rand(4,1);b=rand(4,1)/5; h=mybar(a,b,[],[],'rgby');
% OR:      mybar(a,b,[],[],[1 0 0;0 1 0;0 0 1;1 1 0]);
%
%  06/2005  ras now allows col, xstr, and ystr to be entered as cells

%%%%%% parse inputs %%%%%
if nargin==1, s=zeros(size(f));                                 end
if ~exist('col','var') | isempty(col), col='brgmyck';           end
if ~exist('lineWidth','var') | isempty(lineWidth), lineWidth=2; end
if ~exist('w','var') | isempty(w), w=0.65;                      end
if ~exist('we','var') | isempty(we), we=0.3;                    end

if(size(f,1)==1),
    % row vector instead of column -- be flexible:
    f=f';
    s=conj(s');
end

if (isreal(s)),   s = s+sqrt(-1)*s;                             end

% if col is a cell, convert to N x 3 color table
if iscell(col),   col = cell2ColorOrder(col);                   end
% size(col)
% size(f)

% ensure col spans all columns in f -- repeat colors if needed
if ischar(col)
    while length(col) < max(size(f))
        col = [col,col];
    end
else
    while size(col,1) < max(size(f))
        col = [col; col];
    end
end

sizeShift=.01; % creates space between bars in histogram ADDED LGA 10-11-05


nsubbars=size(f,2);
we=we/nsubbars;

heldstate=ishold;
plot(0,0)
set(gca,'XLim',[1-w,size(f,1)+w]);

yhilim = max(max(f+s))*1.2;
if ~isnan(yhilim)
    %set(gca,'YLim',[0,yhilim]);
end

subx=linspace(-w/2,w/2,nsubbars+1);

newplot(gca)
hold off;
hIndex=1;
for subbar=1:nsubbars
    x=[];
    y=[];
    for i=1:size(f,1);
        tempx= [i+subx(subbar),i+subx(subbar),(i+subx(subbar+1))-sizeShift,(i+subx(subbar+1))-sizeShift];
        tempy= [0,f(i,subbar),f(i,subbar),0];

        % I can find a way to add some spacing here is I want!!! - LGA
        % 101105

        if size(f,2)==1
            % single column -- each bar a diff't color
            if ischar(col)
                thisCol=col(i);
            else
                thisCol=col(i,:);

            end

            h{hIndex}=fill(tempx',tempy',thisCol);
            hold on;

        else
            % multiple columns -- each sub-bar a diff't color
            if ischar(col)
                thisCol=col(subbar);
            else
                thisCol=col(subbar,:);
            end

            h{hIndex}=fill(tempx',tempy',thisCol);
            hold on;

        end
        hIndex=hIndex+1;
        x=[x';tempx]';
        y=[y';tempy]';
    end
    %   if ((length(col)==size(f,1)) & (size(f,2)==1))
    %      % do somethign!
    %   end
    %
    %   h(subbar)={fill(x,y,col(subbar))};
    %
    a=line(get(gca,'XLim'),[0,0]);
    set(a,'Color','k');

    errx=mean([subx(subbar),subx(subbar+1)]);

    for i=1:size(f,1)

        line([i+subx(subbar),i+subx(subbar),i+subx(subbar+1)-sizeShift,i+subx(subbar+1)-sizeShift], ...
            [0,f(i,subbar),f(i,subbar),0],'Color','k','lineWidth',2);

        g=line([i+errx-sizeShift/2,i+errx-sizeShift/2],[f(i,subbar)-imag(s(i,subbar)),f(i,subbar)+real(s(i,subbar))],...
            'Color','k','lineWidth',lineWidth);
        g=line([i+errx-we/2-sizeShift/2,i+errx+we/2-sizeShift/2],[f(i,subbar)-imag(s(i,subbar)),f(i,subbar)-imag(s(i,subbar))],...
            'Color','k','lineWidth',lineWidth);
        g=line([i+errx-we/2-sizeShift/2,i+errx+we/2-sizeShift/2],[f(i,subbar)+real(s(i,subbar)),f(i,subbar)+real(s(i,subbar))],...
            'Color','k','lineWidth',lineWidth);
    end
    %     for i=1:size(f,1)
    %         line([i+subx(subbar),i+subx(subbar),i+subx(subbar+1),i+subx(subbar+1)], ...
    %             [0,f(i,subbar),f(i,subbar),0],'Color','k','lineWidth',lineWidth);
    %         g=line([i+errx,i+errx],[f(i,subbar)-imag(s(i,subbar)),f(i,subbar)+real(s(i,subbar))],...
    %             'Color','k','lineWidth',lineWidth);
    %         g=line([i+errx-we/2,i+errx+we/2],[f(i,subbar)-imag(s(i,subbar)),f(i,subbar)-imag(s(i,subbar))],...
    %             'Color','k','lineWidth',lineWidth);
    %         g=line([i+errx-we/2,i+errx+we/2],[f(i,subbar)+real(s(i,subbar)),f(i,subbar)+real(s(i,subbar))],...
    %             'Color','k','lineWidth',lineWidth);
    %     end
    %hold on
end 					%subbars

% Xlabels
set(gca,'xLimMode','manual');
set(gca,'XTick',[1:size(f,1)]);
if (exist('xstr')) & ~isempty(xstr)
    if ~isempty(xstr)
        set(gca,'XTickLabel',xstr);
    end
end

% Legend
if (exist('ystr')) & ~isempty(ystr)

    %heighten the graph
    ylim=get(gca,'Ylim');
    nLines = length(ystr);
    yMult = 1 + nLines/4; % Each legend line uses about 1/8th of the window height
    set(gca,'YLim',[ylim(1),ylim(2)*yMult]);
    bs=8;

    posgca=get(gca,'Position');
    posgcf=get(gcf,'Position');
    dx=diff(get(gca,'XLim'))/(posgca(3)*posgcf(3));
    dy=diff(get(gca,'YLim'))/(posgca(4)*posgcf(4));

    bw=bs*dx; 				%box width
    bh=bs*dy; 				%box height

    yspace=3.5*bh; 			%vertical spacing

    xlim=get(gca,'Xlim');
    ylim=get(gca,'Ylim');

    xc=xlim(1)+50*dx;
    yc=ylim(2)-30*dy;
    bx=[xc-bw,xc+bw,xc+bw,xc-bw,xc-bw];
    by=[yc+bh,yc+bh,yc-bh,yc-bh,yc+bh];

    textx=xc+bw+10*dx;
    texty=yc;

    %draw box and text
    for i=1:nLines
        if iscell(ystr)
            label = ystr{i};
        else
            label = ystr(i,:);
        end
        if size(col, 1) == 1
            fill(bx,by,col(i));
        else
            fill(bx,by,col(i,:));
        end
        line(bx,by,'lineWidth',lineWidth,'Color','k');
        text(textx,texty,label);
        by=by-yspace;
        texty=texty-yspace;

    end
end
set(gca,'XLim',[1-w,size(f,1)+w]);

if (heldstate==0)
    hold off
end

return
