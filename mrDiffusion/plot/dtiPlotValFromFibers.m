function fgData = dtiPlotValFromFibers(dt6,fg,xform,valName,interpMethod,numSteps,labelStr)
% Plots tensor properties along the fiber group
% 
%    fgData = dtiPlotValFromFibers(dt6,fg,xform,[valName],[interpMethod],[numSteps],[labelStr])
%
% Inputs:
%    dt6          - dt6 data (XxYxZx6)
%    fg           - fiber group structure
%    xform        - the transform that converts fg's coords to dt6 indices
%    valName      - 'eigVal', 'shape', 'fa', 'md', or 'val' (default = 'fa');
%    interpMethod - 'nearest', 'trilin', or 'spline' (default = 'trilin');
%    numSteps     - number of steps along the fiber pathways to be plotted
%    labelStr     - Display string for plotting values (this will be
%                   overwritten for valName = 'shape' or 'eigVal'.
%
% Output:
%    fgData - If valName is 'eigVal' or 'shape', fgData is a 3x1 cell
%             object.  The cell contains data for 1st, 2nd and 3rd
%             eigenvalues or linearity, planarity and sphericity.
%             Otherwise, fgData contains the data for fractional anisotropy
%             or mean diffusivity.
% 
% Example 1 (DTI data):
%    % load dt6 data
%    subjDir = 'C:\cygwin\home\sherbond\data\dla050311';
%    dt = load(fullfile(subjDir,'dti06','dt6.mat'));
%    [dt6, xformToAcpc, mmPerVoxel] = dtiLoadTensorsFromNifti(fullfile(subjDir,dt.files.tensors));
% 
%    % load fiber group data
%    fg = dtiReadFibers(fgFile);
% 
%    fgData = dtiPlotValFromFibers(dt6,fg,inv(xformToAcpc),'shape');
%
% Example 2 (Scalar data):
%    % load dt6 data
%    subjDir = 'C:\cygwin\home\sherbond\data\dla050311';
%    dt = load(fullfile(subjDir,'dti06','dt6.mat'));
%    pddD = niftiRead(fullfile(subjDir,dt.files.pddDisp));
%    xformToAcpc = pddD.qto_xyz;
%    pddD = pddD.data;
% 
%    % load fiber group data
%    fg = dtiReadFibers(fgFile);
% 
%    fgData = dtiPlotValFromFibers(pddD,fg,inv(xformToAcpc),'val',[],[],'Dispersion (degrees)');
% 
% History:
%    2007/01/02 shc (shcheung@stanford.edu) wrote it.
%    2007.10.04 AJS: New data format handling.
%    2007.10.04 AJS: Scalar value plotting.
%

if ieNotDefined('valName'),      valName = 'fa';                              end
if ieNotDefined('interpMethod'), interpMethod = 'trilin';                     end
if ieNotDefined('numSteps'),     numSteps = max(cellfun('size',fg.fibers,2)); end

%% Get the data from the dt6 structure
data     = dtiGetValFromFibers(dt6,fg,xform,'dt6',interpMethod);
numPaths = length(fg.fibers);

%% Get the data for plotting
valName = lower(valName);
switch valName
    case { 'eigval','shape' }
        eigVal   = cell(numPaths,1);
        for ii = 1:numPaths,
            [tmp,eigVal{ii}] = dtiEig(data{ii});
        end
        clear tmp;
        fgData = cell(3,1);
        for ii = 1:numPaths
            numSamp = min([numSteps,length(eigVal{ii})]);
            if strcmp(valName,'shape')
                westin = cell(3,1);
                [westin{1},westin{2},westin{3}] = dtiComputeWestinShapes(eigVal{ii});
            end
            for jj = 1:3
                fgData{jj}(ii,1:numSteps) = NaN;
                if strcmp(valName,'shape')
                    fgData{jj}(ii,1:numSamp) = westin{jj}(1:numSamp);
                else
                    fgData{jj}(ii,1:numSamp) = eigVal{ii}(1:numSamp,jj);
                end
            end
        end
    case { 'fa','md' }
        eigVal   = cell(numPaths,1);
        for ii = 1:numPaths,
            [tmp,eigVal{ii}] = dtiEig(data{ii});
        end
        clear tmp;
        fgData = ones(numPaths,numSteps) * NaN;
        for ii = 1:numPaths
            numSamp = min([numSteps,length(eigVal{ii})]);
            [fa,md] = dtiComputeFA(eigVal{ii});
            if strcmp(valName,'fa')
                fgData(ii,1:numSamp) = fa(1:numSamp);
            else
                fgData(ii,1:numSamp) = md(1:numSamp);
            end
        end
    case 'val'
        fgData = ones(numPaths,numSteps) * NaN;
        for ii = 1:numPaths
            numSamp = min([numSteps,length(data{ii})]);
            fgData(ii,1:numSamp) = data{ii};
        end       
end

%% Plot data
fontSize = 14;
diffusivityUnitStr = '(\mum^2/s)';
if iscell(fgData)
    if strcmp(valName,'shape')
        valLabel = { 'linearity', 'planarity', 'sphericity' };
    else
        valLabel = { '1st EigVal', '2nd EigVal', '3rd EigVal' };
    end
    nodeDist = cumsum([0, sqrt(sum(diff(fg.fibers{1},1,2).^2))]);
    for ii = 1:3
        newGraphWin;
        set(gcf,'Name',sprintf('Fiber property: %s',valLabel{ii}));
        hold on;
        for jj = 1:numPaths
            plot(nodeDist,fgData{ii}(jj,:),'g:');
        end
        errorbar(nanmean(fgData{ii}),nanstd(fgData{ii}),'k-','linewidth',2);
        hold off;
        set(gca,'FontSize',fontSize);
        xlabel('distance from starting point (mm)','FontSize',fontSize);
        if strcmp(valName,'shape')
            labelStr = valLabel{ii};
        else
            labelStr = sprintf('%s %s',valLabel{ii},diffusivityUnitStr);
        end
        ylabel(labelStr,'FontSize',fontSize);
        grid on;
        set(gca,'UserData',fgData{ii});
    end
else
    newGraphWin;
    if ieNotDefined('labelStr')
        set(gcf,'Name',sprintf('Fiber property: %s',valName));
    else
        set(gcf,'Name',sprintf('Fiber property: %s',[labelStr(1:4) '.']));
    end
    hold on;
    for jj = 1:numPaths
        plot(fgData(jj,:),'g:');
    end
    errorbar(nanmean(fgData),nanstd(fgData),'k-','linewidth',2);
    hold off;
    set(gca,'FontSize',fontSize);
    xlabel('1-mm step from starting point','FontSize',fontSize);
    if ieNotDefined('labelStr')
        if strcmp(valName,'fa')
            labelStr = 'Fractional Anisotropy';
        elseif strcmp(valName,'md')
            labelStr = sprintf('Mean Diffusivity %s',diffusivityUnitStr);
        else
            labelStr = 'Unknown Value';
        end
    end
    ylabel(labelStr,'FontSize',fontSize);
    grid on;
    set(gca,'UserData',fgData);
end

%% Done
return
