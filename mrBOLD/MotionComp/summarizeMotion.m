function anal = summarizeMotion(sessions,pptFile,scansToCompare,sesspar);
%
% summarizeMotion(sessions,[pptFile],[scansToCompare],[sesspar]):
%
% Create a series of figures (and export to a powerpoint
% file if desired) summarizing the motion between scans
% across a session, for one or more sessions.
%
% The 'summary' is fairly crude and simple, right now:
% for each session, it loads up the mean map (computes
% it if it's not there), makes a montage of the mean
% tSeries from the first and last scans (other pairs
% can be specified), and overlays them using overlayVolumes.
% It does this twice, once using bluegreen and red colormaps
% (so overlap shows up as gray), and once using thresholded
% binary red and green cmaps (so overlap shows up as yellow,
% and red and green at the edge indicates non-alignment).
%
% Then, if it finds a motion-corrected data type (looks 
% for the names 'mc' or 'MotionCorrected'-- feel free to
% add more possibilities in the code), it does the same
% for that data type, and plots the results side-by-side,
% to give a rough sense of how well the motion correction
% helped.
% 
%
% sessions: a cell array specifying the location of 
% session directories to look at. Each entry can
% be an absolute or relative path to that directory.
%
% pptFile: if specified, will export each
% figure into a slide in a power point file with
% the given name.
%
% scansToCompare: By default, the first and last
% scan in each session are compared. If a different
% pairing matters (e.g., you know the subject moved 
% in the first scan and want to compare the second
% and last scans), enter this as a cell array, same
% size as sessions, with each entry being a vector
% w/ the two scan numbers ... e.g., for {[2 10] []},
% the first session will compare scans 2 and 10, but
% the second, since this is empty, will default to 1st
% and last.
%
% sesspar: session parent directory.
%
%
% 01/05 ras.
if nargin < 1
    help summarizeMotion
    return
end

if ieNotDefined('pptFile')
    pptFile = [];
end

if ieNotDefined('sesspar')
    sesspar = [];
end

if ieNotDefined('scansToCompare')
    scansToCompare = cell(size(sessions));
end

if isempty(sesspar)
    sesspar = pwd;
end

callingDir = pwd;

%%%%%%%%%%%%%
% open ppt  %
%%%%%%%%%%%%% 
if ~isempty(pptFile)   
    % Start an ActiveX session with PowerPoint:
	ppt = actxserver('PowerPoint.Application');
	ppt.Visible = 1;

    if ~exist(pptFile,'file');
      % Create new presentation:
      op = invoke(ppt.Presentations,'Add');
	else
      % Open existing presentation:
      op = invoke(ppt.Presentations,'Open',pptFile);
	end
end

for sess = 1:length(sessions)
    cd(sesspar);
    cd(sessions{sess});
    fprintf('\n\tGetting mean images from %s ...\n\n',pwd);

    % init hidden view    
    mrGlobals;
    HOMEDIR = pwd;
    loadSession;
    hI = initHiddenInplane;
    
    % figure out scans to compare
    if isempty(scansToCompare{sess})
        scans = [1 numScans(hI)];
    else
        scans = scansToCompare{sess};
    end
    
    % figure out which data types to
    % run through
    names = {dataTYPES.name};
    dts = cellfind(lower(names),'original');
    dts = [dts cellfind(lower(names),'motioncorrected')];
    dts = [dts cellfind(lower(names),'mc')];

    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % loop through data types %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    for j = 1:length(dts)
        % select proper data type
        dt = dts(j);
        hI = selectDataType(hI,dt);
        
        % load / compute mean map for scans
        hI = loadMeanMap(hI);
        if isempty(hI.map{scans(1)})
            hI = computeMeanMap(hI,scans(1),1);
        end
        if isempty(hI.map{scans(2)})
            hI = computeMeanMap(hI,scans(2),1);
        end
        
        % get montage images of all slices
        montage1 = makeMontage(hI.map{scans(1)});
        montage2 = makeMontage(hI.map{scans(2)});
        
        % also get middle slice -- better to take
        % a closer look at a single slice
        % (chose middle b/c motion-cor may screw up edges)
        mid = round(numSlices(hI)/2);
        slc1 = hI.map{scans(1)}(:,:,mid);
        slc2 = hI.map{scans(2)}(:,:,mid);       
               
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % grab images:                 %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         % 1) bluegreen + red cmaps, montage 
%         h = overlayVolumes(montage1,montage2);
%         imgs{j,1} = get(get(gca,'Children'),'CData');
%         close(h)
%         
        % 2) binary red + green cmaps, thresholded, montage
        % (Trickier b/c have to threshold)
        h = overlayVolumes(montage1,montage2,[],{'Green Binary' 'Red Binary'});
        info = get(h,'UserData');
        min1 = get(info.handles.sliders(2),'Min');
        max1 = get(info.handles.sliders(2),'Max');
        min2 = get(info.handles.sliders(3),'Min');
        max2 = get(info.handles.sliders(3),'Max');
        thresh1 = min1 + 0.1*(max1-min1);
        thresh2 = min2 + 0.1*(max2-min2);
        set(info.handles.sliders(2),'Value',thresh1);
        set(info.handles.sliders(3),'Value',thresh2);
        overlayVolumes(h); % refresh UI w/ thresholds
        imgs{j,1} = get(findobj('Parent',gca,'Type','image'),'CData');
        close(h)
        
        % 3) bluegreen + red cmaps, middle slice
        h = overlayVolumes(slc1,slc2);
        imgs{j,2} = get(findobj('Parent',gca,'Type','image'),'CData');
        close(h)
        
%         % 4) binary red + green cmaps, thresholded, single
%         h = overlayVolumes(slc1,slc2,[],{'Green Binary' 'Red Binary'});
%         info = get(h,'UserData');
%         min1 = get(info.handles.sliders(2),'Min');
%         max1 = get(info.handles.sliders(2),'Max');
%         min2 = get(info.handles.sliders(3),'Min');
%         max2 = get(info.handles.sliders(3),'Max');
%         thresh1 = min1 + 0.1*(max1-min1);
%         thresh2 = min2 + 0.1*(max2-min2);
%         set(info.handles.sliders(2),'Value',thresh1);
%         set(info.handles.sliders(3),'Value',thresh2);
%         overlayVolumes(h); % refresh UI w/ thresholds
%         imgs{j,4} = get(get(gca,'Children'),'CData');
%         close(h)
    end
    
    %%%%%%%%%%%%
    % clean up %
    %%%%%%%%%%%%
    clear hI;
    mrvCleanWorkspace;
    cd(sesspar);
    
    %%%%%%%%%%%%%%%%%%%%%%%
    % put up some figures %
    %%%%%%%%%%%%%%%%%%%%%%%     
    for k = 1:2
        for j = 1:length(dts)
            h = figure('Units','Normalized','Position',[0 .15 .4 .4]);
            imagesc(imgs{j,k});
            colormap gray;
            axis equal;
            axis off;
            
            ttl = sprintf('%s: %s',sessions{sess},names{j});
            set(h,'Name',ttl);
            title(ttl,'FontName','Helvetica','FontSize',24);
            
            % export to ppt
            if ~isempty(pptFile) & ispc
                pastePPT(op,gcf,'meta');
            end            
            close(h)
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % create output structure, if requested %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if nargout > 0
        anal(sess).imgs = imgs;
        anal(sess).session = sessions{sess};
        anal(sess).scans = scans;
        anal(sess).dts = dts;
        if ~isempty(pptFile)
            anal(sess).pptFile = pptFile;
        end
    end        
end

fprintf('Done looping through sessions. Finishing up...');

%%%%%%%%%%%%%%
% Close ppt  %
%%%%%%%%%%%%%%
if ~isempty(pptFile)
    cd(sesspar);
    
	if ~exist(pptFile,'file')
      % Save file as new:
      invoke(op,'SaveAs',pptFile,1);
	else
      % Save existing file:
      invoke(op,'Save');
	end
	
	% Close the presentation window:
	invoke(op,'Close');
    
	% Quit PowerPoint
	invoke(ppt,'Quit');
	
	% Close PowerPoint and terminate ActiveX:
	delete(ppt);
end

cd(callingDir);

fprintf('All Done.\n\n\n');

return
% /-----------------------------------------------------------/ %




% /-----------------------------------------------------------/ %
function pastePPT(op,fig,fmt);
% Replacement for saveppt, which crashes with
% gusto. The ActiveX PowerPoint file should
% already be opened (op is the project
% object). fig is a handle to the figure
% to paste. fmt is a format string: 'meta'
% or 'bitmap'. Defaults to bitmap.
% No titles right now.
if ieNotDefined('fmt')
    fmt = '-dbitmap';
else
    fmt = ['-d' fmt];
end

if ieNotDefined('fig')
    fig = gcf;
end

% paste figure into clipboard
figure(fig);
print(fmt);

% Get current number of slides:
slide_count = get(op.Slides,'Count');

% Add a new slide (no title object):
slide_count = int32(double(slide_count)+1);
new_slide = invoke(op.Slides,'Add',slide_count,12);

% % Insert text into the title object:
% set(new_slide.Shapes.Title.TextFrame.TextRange,'Text',titletext);

% Get height and width of slide:
slide_H = op.PageSetup.SlideHeight;
slide_W = op.PageSetup.SlideWidth;

% Paste the contents of the Clipboard:
pic1 = invoke(new_slide.Shapes,'Paste');

% Set picture to fill slide:
set(pic1,'Height',slide_H);
set(pic1,'Width',slide_W);

% % Get height and width of picture:
% pic_H = get(pic1,'Height');
% pic_W = get(pic1,'Width');

% Center picture on page:
% set(pic1,'Left',single((double(slide_W) - double(pic_W)/2)));
% set(pic1,'Top',single(double(slide_H) - double(pic_H)));
set(pic1,'Left',0);
set(pic1,'Top',0);


return
