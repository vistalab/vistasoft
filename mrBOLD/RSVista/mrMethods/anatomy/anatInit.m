function mr = anatInit(inputFiles, params, savePath);
% Initialize an anatomy, launching a GUI to facilitate the process if
% desired.
%
%  mr = anatInit(<inputFiles>, <params=launch GUI>, <savePath=vAnatomy.img>);
%
% This function initializes anatomies, loading from "raw" formats such as DICOM or
% Genesis I-files, and offering the following preprocessing options:
%   * averaging multiple anatomies, aligning using the SPM tools
%   * iso-voxeling (resampling to 1 x 1 x 1 mm, or another desired
%   resolution, using SPM b-spline interpolation)
%   * rotating to align into AC/PC space
%   
% It saves the results as an ANALYZE 7.5 format file vAnatomy.img (and
% .hdr), by default, as well as a mrGray-format vAnatomy.dat. It can also
% save as any mrVista 2-supported format, such as NIFTI or native matlab .mat 
% file. 
%
% USAGE:
%   COMMAND LINE: 
%   (1) the 'inputFiles' argument should be a string (1 file) or
%   cell-of-strings (many files), specifying the path to each anatomy to
%   average. For DICOM / I-files, you can just specify the directory, e.g.
%   '/data/myAnatomy/spgr1/'. Can also specify any mrVista2-readable input
%   files, such as ANALYZE, NIFTI, or mrVista 1 format files. If more than
%   one input file
%
%   (2) 'params' is a struct with analysis parameters. Should have the
%   following fields:
%       * voxelSize: [1 x 3] target size to which to resample the output anatomy, 
%        in mm. Directions are [axial coronal sagittal]. If omitted, uses
%        [1 1 1].
%       * ac: If provided (along with the 'pc' and 'midSag' fields
%       described below), will AC/PC align the anatomy. The format is to
%       describe the [row column slice] in the first input file which marks
%       the location of the anterior commisure.
%       * pc: location of the posterior commisure, in the same format as
%       ac.
%       * midSag: location of a point in the mid-sagittal plane that is
%       somewhat away from the AC-PC line, in the same format as ac and pc.
%       * boundingBox: dimensions of the bounding box from which to take
%       the final, averaged and resampled data, in voxels:
%           [axial range; coronal range; sagittal range]from the AC. 
%       If omitted, uses [-90 90; -126 90; -72 108].
%       * showFigs: flag to show figures w/ results of intermediate computations.
%       * weights: optional weights for each of the input files (if >1).
%       Uses these weights in determining the average (e.g., if one scan
%       went better or is of a higher quality). If omitted, uses equal
%       weights for each input file.
%       * format: specify save format. If omitted, uses ANALYZE 7.5 format,
%       and converts this to a volume anatomy.
%       * clipVals: clip values to use when converting from ANALYZE / NIFTI
%       to vAnatomy.dat.
%       * saveIntermediate: flag to keep the intermediate files created as part of
%       the process. If omitted, deletes the files (saveIntermediate=0).
%       
%   (3) 'savePath' is a path to the output anatomy file. Defaults to
%   vAnatomy.img. 
%
%   GUI: 
%   If the 'params' argument is omitted (or left empty), a GUI pops up,
%   along with a mrViewer interface (see mrViewer), to facilitate selecting
%   AC/PC/midsag points and setting parameters.  Note that the mrViewer GUI
%   allows you to switch between different coordinate conventions
%   (pixels/mm; neurological coords/mrGray coords; etc). The GUI will take
%   the set points and convert them into the proper format for the
%   preprocessing.
%
% This code mostly serves as a more accesible shell for the mrVista 1.0
% function mrAnatAverageAcpcAnalyze. 
%
% For more instructions, please see:
%       http://white.stanford.edu/newlm/index.php/Anatomical_Methods
%
% ras, 06/2006
if notDefined('inputFiles'),    inputFiles = {};                             end
if ~iscell(inputFiles),         inputFiles = {inputFiles};                   end
if notDefined('savePath'),      savePath = 'vAnatomy.img';                   end

callingDir = pwd; % remember this directory for relative paths

% if input files are not ANALYZE, convert to Analyze
tmpFile = {}; % list of any intermediate files...
for i = 1:length(inputFiles)
    [p f ext] = fileparts(inputFiles{i}); 
    
    if ismember(lower(ext), {'.img' '.hdr' '.nii'})
        inputAnalyze{i} = inputFiles{i};
        
    elseif isequal(lower(ext), '.dcm') | isequal(f, 'I')
        % assume directory of DICOM or GE I-files, w/ first file specified
        tmpFile{end+1} = fullfile(callingDir, sprintf('tmpAnatInit%i',i));
        makeAnalyzeFromIfiles(fullfile(p, 'I'), tmpFile{end});
        inputAnalyze{i} = [tmpFile{end} '.img'];
    else
        % assume directory of DICOM or GE I-files, directory specified
        tmpFile{end+1} = fullfile(callingDir, sprintf('tmpAnatInit%i',i));
        makeAnalyzeFromIfiles(fullfile(inputFiles{i}, 'I'), tmpFile{end});
        inputAnalyze{i} = [tmpFile{end} '.img'];
        
    end    
end

if notDefined('params')
    anatInitGUI(inputAnalyze, savePath); 
    return;
else
    % see what input params are provided, adding default values as needed.
    params = parseParams(params); 
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% main part: call SPM tools  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[par outputBase ext] = fileparts(savePath);
if findstr('.nii', outputBase) % ext was .nii.gz
    outputBase = outputBase(1:end-4);
    ext = '.nii.gz';
end
    
if ~(isempty(params.ac) | isempty(params.pc) | isempty(params.midSag))
    landmarks = [params.ac; params.pc; params.midSag];
    
    % need to flip from I|P|R space into R|A|S space for SPM tools
    hdr = readAnalyzeHeader(inputAnalyze{1});
%     landmarks = landmarks(:,[3 2 1]);
%     landmarks(:,2) = hdr.dim(3) - landmarks(:,2); % coronal A->P to P->A
%     landmarks(:,3) = hdr.dim(4) - landmarks(:,3); % axi S->I to I->S

    % save the info
    save('ACPC_points', 'inputAnalyze', 'inputFiles', 'landmarks', 'params');
else
    landmarks = [];
end
if exist(par, 'dir'),    cd(par);       end

mrAnatAverageAcpcAnalyze(inputAnalyze, outputBase, landmarks, params.voxelSize, ...
                        params.weights, params.boundingBox', params.clipVals, ...
                        params.showFigs);

% create vAnatomy.dat
createVolAnat([outputBase '.img'], [outputBase '.dat']);                    
                        
% if using format other than ANALYZE, convert to final format                
if ~isequal(lower(params.format), 'analyze')
    mr = mrLoad([outputBase '.img']);
    
    % append the header information from the raw data as well
    raw = mrLoad(inputFiles{1});
    mr.info = raw.info;
    if ~checkfields(mr, 'info', 'history')
        mr.info.history = sprintf('anatInit %s', datestr(now));
    else
        mr.info.history = [mr.info.history sprintf('anatInit %s', datestr(now))];
    end            
    
    mrSave(mr, savePath, params.format);
    
    if params.saveIntermediate==0
        delete([outputBase '.img']);
        delete([outputBase '.hdr']);
    end
end

% clean up
if params.saveIntermediate==0 
    for i = 1:length(tmpFile)
        delete(tmpFile{i})
    end    
end
cd(callingDir);

return
% /--------------------------------------------------------------------/ %





% /--------------------------------------------------------------------/ %
function params = parseParams(params);
% check params struct for omitted fields, assigning default values if
% needed.
if ~isfield(params, 'voxelSize') | isempty(params.voxelSize)
    params.voxelSize = [1 1 1];
    
    % check if an older field name was used:
    if isfield(params, 'mmPerVox') & ~isempty(params.mmPerVox)
        params.voxelSize = params.mmPerVox;
    end
end

if ~isfield(params, 'ac'), params.ac = []; end
if ~isfield(params, 'pc'), params.pc = []; end
if ~isfield(params, 'midSag'), params.midSag = []; end

if ~isfield(params, 'boundingBox') | isempty(params.boundingBox)
    params.boundingBox = [-90 90; -126 90; -72 108];
end

if ~isfield(params, 'showFigs') | isempty(params.showFigs)
    params.showFigs = 1;
end

if ~isfield(params, 'saveIntermediate') | isempty(params.saveIntermediate)
    params.saveIntermediate = 0;
end

if ~isfield(params, 'weights'), params.weights = []; end
    
if ~isfield(params, 'clipVals') | isempty(params.clipVals)
    params.clipVals = [];
end

if ~isfield(params, 'format') | isempty(params.format)
    params.format = 'analyze';
end

return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function [inputFiles, params, savePath] = anatInitGUI(inputFiles, savePath);
% Get arguments for anatInit from a GUI.
% If preliminary input files are provided as an input argument, will 
% open a mrViewer GUI to steer through that for the AC, PC, and midSag
% points.
if notDefined('inputFiles'), inputFiles = {}; end
if notDefined('savePath'), savePath = 'vAnatomy.dat'; end

% get initial/default parameters
params = parseParams(struct('voxelSize', [1 1 1]));
params.inputFiles = inputFiles;
params.savePath = savePath;

%%%%% open a mrViewer GUI for the first input file
if length(inputFiles) >= 1
    mrViewer(inputFiles{1});
end

%%%%% create the figure
hfig = figure('Units', 'normalized', 'Position', [.7 .3 .3 .6], ...
              'Name', 'mrVista anatInit', 'Color', [.9 .9 .9], ...
              'NumberTitle', 'off', 'UserData', params);
          
%%%%% add a list box for setting input files
uicontrol('Units', 'normalized', 'Position', [.1 .9 .8 .06], ...
          'Style', 'text', 'String', 'Input Files', ...
          'HorizontalAlignment', 'left', ...
          'FontSize', 12, 'FontName', 'Arial', 'FontWeight', 'bold', ...
          'BackgroundColor', [.9 .9 .9], 'ForegroundColor', [0 0 0]);

cb = ['params = get(gcf, ''UserData''); ' ...
      'params.inputFiles = get(gcbo, ''String''); ' ...
      'set(gcf, ''UserData'', params); '];
params.inputList = uicontrol('Units', 'normalized', 'Position', [.3 .75 .6 .15], ...
          'Style', 'listbox', 'String', params.inputFiles, 'Callback', cb, ...
          'FontSize', 10, 'FontName', 'Arial', 'BackgroundColor', [1 1 1]);
      
% add buttons for loading new input files, removing existing ones
cb = ['params = get(gcf, ''UserData''); ' ...
      '[f p] = uigetfile(''*.*'', ''Select An Input File''); ' ...
      'params.inputFiles{end+1} = fullfile(p, f); ' ...
      'if isempty(mrViewGet), mrViewer(params.inputFiles{1}); end; ' ...
      'set(params.inputList, ''String'', params.inputFiles); ' ...
      'set(gcf, ''UserData'', params); clear p f '];
uicontrol('Units', 'normalized', 'Position', [.1 .85 .2 .04], ...
          'Style', 'pushbutton', 'String', 'Add', 'Callback', cb, ...
          'FontSize', 9, 'FontName', 'Arial', 'BackgroundColor', [1 1 1]);
      
cb = ['params = get(gcf, ''UserData''); ' ...
      'val = get(params.inputList, ''Value''); ' ...
      'nInput = length(params.inputList); ' ...
      'params.inputFiles = params.inputFiles(setdiff(1:nInput, val)); ' ...
      'set(params.inputList, ''String'', params.inputFiles); ' ...
      'set(gcf, ''UserData'', params); clear val nInput '];
uicontrol('Units', 'normalized', 'Position', [.1 .8 .2 .04], ...
          'Style', 'pushbutton', 'String', 'Remove', 'Callback', cb, ...
          'FontSize', 9, 'FontName', 'Arial', 'BackgroundColor', [1 1 1]);

          
%%%%% add edit fields to manually set the AC, PC, and MidSag points
uicontrol('Units', 'normalized', 'Position', [.1 .68 .8 .06], ...
          'Style', 'text', 'String', 'Parameters', ...
          'HorizontalAlignment', 'left', ...
          'FontSize', 12, 'FontName', 'Arial', 'FontWeight', 'bold', ...
          'BackgroundColor', [.9 .9 .9], 'ForegroundColor', [0 0 0]);

cb = ['params = get(gcf, ''UserData''); ' ...
      'params.ac = str2num(get(gcbo, ''String'')); ' ...
      'set(gcf, ''UserData'', params); '];
params.acEdit = uicontrol('Units', 'normalized', 'Position', [.5 .65 .4 .03], ...
          'Style', 'edit', 'String', '', 'Callback', cb, ...
          'FontSize', 9, 'FontName', 'Arial', 'BackgroundColor', [1 1 1]);
      
cb = ['params = get(gcf, ''UserData''); ' ...
      'params.pc = str2num(get(gcbo, ''String'')); ' ...
      'set(gcf, ''UserData'', params); '];
params.pcEdit = uicontrol('Units', 'normalized', 'Position', [.5 .61 .4 .03], ...
          'Style', 'edit', 'String', '', 'Callback', cb, ...
          'FontSize', 9, 'FontName', 'Arial', 'BackgroundColor', [1 1 1]);
      
cb = ['params = get(gcf, ''UserData''); ' ...
      'params.midSag = str2num(get(gcbo, ''String'')); ' ...
      'set(gcf, ''UserData'', params); '];
params.msEdit = uicontrol('Units', 'normalized', 'Position', [.5 .57 .4 .03], ...
          'Style', 'edit', 'String', '', 'Callback', cb, ...
          'FontSize', 9, 'FontName', 'Arial', 'BackgroundColor', [1 1 1]);
      
      
      
% add buttons to set the AC, PC, and MidSag points from the mrViewer UI:
cb = ['params = get(gcf, ''UserData''); ' ...
      'params.ac = round(mrViewGet([], ''cursorDataCoords'')); ' ...
      'set(params.acEdit, ''String'', num2str(params.ac)); ' ...
      'set(gcf, ''UserData'', params); '];
uicontrol('Units', 'normalized', 'Position', [.1 .65 .3 .04], ...
          'Style', 'pushbutton', 'String', 'Set AC', 'Callback', cb, ...
          'FontSize', 9, 'FontName', 'Arial', 'BackgroundColor', [.9 .9 1]);

cb = ['params = get(gcf, ''UserData''); ' ...
      'params.pc = round(mrViewGet([], ''cursorDataCoords'')); ' ...
      'set(params.pcEdit, ''String'', num2str(params.pc)); ' ...
      'set(gcf, ''UserData'', params); '];
uicontrol('Units', 'normalized', 'Position', [.1 .61 .3 .04], ...
          'Style', 'pushbutton', 'String', 'Set PC', 'Callback', cb, ...
          'FontSize', 9, 'FontName', 'Arial', 'BackgroundColor', [.9 .9 1]);

cb = ['params = get(gcf, ''UserData''); ' ...
      'params.midSag = round(mrViewGet([], ''cursorDataCoords'')); ' ...
      'set(params.msEdit, ''String'', num2str(params.midSag)); ' ...
      'set(gcf, ''UserData'', params); '];
uicontrol('Units', 'normalized', 'Position', [.1 .57 .3 .04], ...
          'Style', 'pushbutton', 'String', 'Set MidSag', 'Callback', cb, ...
          'FontSize', 9, 'FontName', 'Arial', 'BackgroundColor', [.9 .9 1]);      
          
          
% add button to get clip values from mrViewer UI
cb = ['params = get(gcf, ''UserData''); ui = mrViewGet; ' ...
      'params.clipVals = ui.settings.anatClip; ' ...
      'set(gcf, ''UserData'', params); '];
uicontrol('Units', 'normalized', 'Position', [.1 .5 .3 .04], ...
          'Style', 'pushbutton', 'String', 'Get Clip Vals', 'Callback', cb, ...
          'FontSize', 9, 'FontName', 'Arial', 'BackgroundColor', [1 1 1]);      
          

          
% add an edit field for voxel size
uicontrol('Units', 'normalized', 'Position', [.1 .45 .4 .03], ...
          'Style', 'text', 'String', 'Voxel Size', 'Callback', cb, ...
          'FontSize', 10, 'FontName', 'Arial', 'BackgroundColor', [.9 .9 .9], ...
          'FontWeight', 'bold');

cb = ['params = get(gcf, ''UserData''); ' ...
      'params.voxelSize = str2num(get(gcbo, ''String'')); ' ...
      'set(gcf, ''UserData'', params); '];
uicontrol('Units', 'normalized', 'Position', [.5 .45 .4 .03], ...
          'Style', 'edit', 'String', '1 1 1', 'Callback', cb, ...
          'FontSize', 9, 'FontName', 'Arial', 'FontWeight', 'bold', ...
          'BackgroundColor', [1 1 1]);
      

% add edit fields for the bounding box
uicontrol('Units', 'normalized', 'Position', [.1 .4 .4 .03], ...
          'Style', 'text', 'String', 'Bounding Box (Axi)', 'Callback', cb, ...
          'FontSize', 10, 'FontName', 'Arial', 'BackgroundColor', [.9 .9 .9], ...
          'FontWeight', 'bold');

cb = ['params = get(gcf, ''UserData''); ' ...
      'params.boundingBox(3,:) = str2num(get(gcbo, ''String'')); ' ...
      'set(gcf, ''UserData'', params); '];
uicontrol('Units', 'normalized', 'Position', [.5 .4 .4 .03], ...
          'Style', 'edit', 'String', num2str(params.boundingBox(3,:)), ...
          'Callback', cb, ...
          'FontSize', 9, 'FontName', 'Arial', 'FontWeight', 'bold', ...
          'BackgroundColor', [1 1 1]);

uicontrol('Units', 'normalized', 'Position', [.1 .36 .4 .03], ...
          'Style', 'text', 'String', 'Bounding Box (Cor)', 'Callback', cb, ...
          'FontSize', 10, 'FontName', 'Arial', 'BackgroundColor', [.9 .9 .9], ...
          'FontWeight', 'bold');

cb = ['params = get(gcf, ''UserData''); ' ...
      'params.boundingBox(2,:) = str2num(get(gcbo, ''String'')); ' ...
      'set(gcf, ''UserData'', params); '];
uicontrol('Units', 'normalized', 'Position', [.5 .36 .4 .03], ...
          'Style', 'edit', 'String', num2str(params.boundingBox(2,:)), ...
          'Callback', cb, ...
          'FontSize', 9, 'FontName', 'Arial', 'FontWeight', 'bold', ...
          'BackgroundColor', [1 1 1]);


uicontrol('Units', 'normalized', 'Position', [.1 .32 .4 .03], ...
          'Style', 'text', 'String', 'Bounding Box (Sag)', 'Callback', cb, ...
          'FontSize', 10, 'FontName', 'Arial', 'BackgroundColor', [.9 .9 .9], ...
          'FontWeight', 'bold');

cb = ['params = get(gcf, ''UserData''); ' ...
      'params.boundingBox(1,:) = str2num(get(gcbo, ''String'')); ' ...
      'set(gcf, ''UserData'', params); '];
uicontrol('Units', 'normalized', 'Position', [.5 .32 .4 .03], ...
          'Style', 'edit', 'String', num2str(params.boundingBox(1,:)), ...
          'Callback', cb, ...
          'FontSize', 9, 'FontName', 'Arial', 'FontWeight', 'bold', ...
          'BackgroundColor', [1 1 1]);

      
          

% add an edit field for the save path
uicontrol('Units', 'normalized', 'Position', [.1 .18 .8 .06], ...
          'Style', 'text', 'String', 'Output File', ...
          'HorizontalAlignment', 'left', ...
          'FontSize', 12, 'FontName', 'Arial', 'FontWeight', 'bold', ...
          'BackgroundColor', [.9 .9 .9], 'ForegroundColor', [0 0 0]);

cb = ['params = get(gcf, ''UserData''); ' ...
      'params.savePath = get(gcbo, ''String''); ' ...
      'set(gcf, ''UserData'', params); '];
uicontrol('Units', 'normalized', 'Position', [.5 .2 .4 .03], ...
          'Style', 'edit', 'String', params.savePath, 'Callback', cb, ...
          'FontSize', 10, 'FontName', 'Arial', 'BackgroundColor', [1 1 1]);
      
          
%%%%% finally, the main GO button, that calls the original anatInit function again:
cb = ['params = get(gcf, ''UserData''); ' ...
      'anatInit(params.inputFiles, params, params.savePath); '];
uicontrol('Units', 'normalized', 'Position', [.65 .05 .25 .12], ...
          'Style', 'pushbutton', 'String', 'GO', 'Callback', cb, ...
          'FontSize', 14, 'FontName', 'Arial', 'FontWeight', 'bold', ...
          'ForegroundColor', [1 1 1], 'BackgroundColor', [.2 .7 .2]);
      
set(gcf, 'UserData', params);

return
