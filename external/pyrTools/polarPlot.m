function polarPlot(Z,arg1)
% polarPlot(Z,params)
%   creates a polar plot using the parameters
%   determined by the structure 'params'.
%
% PolarPlot(Z,'PropertyName1',PropertyValue1,'PropertyName2',... );
%   creates a polar plot using the property values and names
%
%   default fields of params or properties:
%      params.grid            = 'on';
%      params.line            = 'on';
%      params.gridColor       = [0.6,0.6,0.6];
%      params.gridLineWidth   = 1;
%      params.fontSize        = 12;
%      params.symbol          = 'os^dp';
%      params.size            = 20;
%      params.color           = 'k';
%      params.fillColor       = [1,1,1;0.6,0.6,0.6;0,0,0];
%      params.lineWidth       = 2;
%      params.backgroundColor = 'w';
%      params.maxAmp          = ceil(max(abs(Z(:)))*10)/10;
%      params.ringTicks       = [0:0.1:defParams.maxAmp];
%	   params.sigFigs		  = 1;
%
%  fillColor loops through the COLUMNS of Z
%  symbols loop through the ROWS of Z
%
%  Example:
%  [x,y] = meshgrid(linspace(0,2*pi,11),linspace(0,2*pi,11));
%  Z = x.*exp(sqrt(-1)*(y+x/5));
%  polarPlot(Z,'fillColor',hsv(11),'grid','off','line','off','size',30)

% 4/9/98 gmb wrote it.
% 3/20/09 ras updated many years later; more flexibility about specifying
% the maximum amplitude of the data, small cleanup using newer matlab
% features.
% 9/17/2016 RL minor clean up to unused input variables, add option to not
% print tick labels (when making figures for paper, often cleaner to add own labels)

%set up default parameters
defParams.grid            = 'on';
defParams.line            = 'on';
defParams.gridColor       = [0.6,0.6,0.6];
defParams.gridLineWidth   = 1;
defParams.fontSize        = 12;
defParams.symbol          = 'os^dp';
defParams.size            = 20;
defParams.color           = 'k';
defParams.fillColor       = [1,1,1;0.6,0.6,0.6;0,0,0];
defParams.lineWidth       = 2;
defParams.backgroundColor = 'w';
defParams.maxAmp          = ceil(max(abs(Z(:)))*10)/10;
defParams.ringTicks       = [0:0.1:defParams.maxAmp];
defParams.sigFigs		  = 1;
defParams.tickLabel       = true; 

% also allow the user to override the default params with whatever fields
% are provided
if ~exist('arg1', 'var')
	params = struct;  % empty structure
else
	params = arg1;
end

% If a string is passed as second argument it must be a property name
% so build the params file from the arguments
if strcmp(class(params),'char')
	for arg=1:2:nargin-1
		estr =['propertyName = arg',int2str(arg),';'];   eval(estr)
		estr = ['params.',propertyName,' = arg',int2str(arg+1),';'];
		eval(estr)
	end
end

% for any parameters not specified by the user, use the default value.
for f = fieldnames(defParams)'
	if ~isfield(params, f{1}) | isempty(params.(f{1}))
		params.(f{1}) = defParams.(f{1});
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Ready to plot

set(gcf,'Color',params.backgroundColor);

hold on
if strcmp(params.grid,'on')
	%% radial lines
	maxRad = max(params.ringTicks);
	for i=linspace(0,pi,5);
		line([-maxRad*cos(i),maxRad*cos(i)],[-maxRad*sin(i),maxRad*sin(i)],...
			'Color',params.gridColor,'lineWidth',params.gridLineWidth);
	end

	%% concentric circles.
	arg = linspace(0,pi*2,64);
	ringTicks = setdiff(params.ringTicks, 0); % we don't want a ring at r=0
	for i=ringTicks
		x = i*cos(arg);
		y = i*sin(arg);
		plot(x,y,'Color',params.gridColor,'lineWidth',params.gridLineWidth);
	end

	%% labels
	% offset from grid
    
    % check that we want labels to begin with
    if params.tickLabel
        if isempty(params.maxAmp), dx = 0.075;
        else,	dx = 0.075 * params.maxAmp;
        end

        % make labels
        for i=params.ringTicks(2:length(params.ringTicks));
            pattern = sprintf('%%3.%if', params.sigFigs);
            text(dx, i+dx, sprintf(pattern,i), 'Color', params.gridColor, ...
                'FontSize', params.fontSize);
        end
    end
end

% %hack:  place four white points in the corners to fix image size
% 
% plot(params.maxAmp*exp(sqrt(-1)*[45,135,225,315]*pi/180),'w.')


%loop through the columns of Z

%lines first
if strcmp(params.line,'on')
	for i=1:size(Z,2)
		color = params.color(mod(i-1,length(params.color))+1);
		for j=1:size(Z,1)
			plot([0,real(Z(j,i))],[0,imag(Z(j,i))],color,...
				'LineWidth',params.lineWidth)
		end
	end
end

%then symbols
for i=1:size(Z,1)
	symbol = params.symbol(mod(i-1,length(params.symbol))+1);
	color = params.color(mod(i-1,length(params.color))+1);
	for j=1:size(Z,2)
		fillColor = params.fillColor(mod(j-1,size(params.fillColor,1))+1,:);

		plot(real(Z(i,j)),imag(Z(i,j)),[symbol,color],...
			'LineWidth',params.lineWidth,...
			'MarkerFaceColor',fillColor,...
			'MarkerSize',params.size)
	end
end

axis off
axis equal

return


