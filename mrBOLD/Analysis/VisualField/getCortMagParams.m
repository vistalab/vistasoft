function cortMag = getCortMagParams(cortMag)
%
%  cortmag = getCortMagParams(cortMag)
%
%  Set up the initial cortMag structure, asking the user for
% information about different parameters. Returns 0 if the user 
% cancels, an updated cortMag struct oitherwise.
%
% HISTORY:
%   2002.03.05 RFD (bob@white.stanford.edu) wrote it, based
%   on 'CortMagUI' by Wandell.%   2002.12.11 RFD: added flatDataFlag.


prompt = {...
    'Bin distance      (mm):', ...
    'Ring Exp        (scan):',...
    'Stim Radius      (deg):',...
    'Co Thresh      (0-1.0):', ...
    'Stim Foveal Ph [0,2pi]:', ...
    'Stim Periph Ph [0,2pi]:', ...
    'Exclude ROIs:', ...
    'Shift Template #:',...    'Use data from flat view:'};

% Default values
def={'4','2','20','0.20','4.71','4.71','','1','0'};

% If CortMag exists, use the existing values as the defaults
%
if isfield(cortMag,'binDist'),        def{1} = num2str(cortMag.binDist); end
if isfield(cortMag,'expNumber'),      def{2} = num2str(cortMag.expNumber); end
if isfield(cortMag,'stimulusRadius'), def{3} = num2str(cortMag.stimulusRadius); end
if isfield(cortMag,'coThresh'),       def{4} = num2str(cortMag.coThresh); end
if isfield(cortMag,'fovealPhase'),    def{5} = num2str(cortMag.fovealPhase); end
if isfield(cortMag,'peripheralPhase'),def{6} = num2str(cortMag.peripheralPhase); end
if isfield(cortMag,'excludeROIs'),    def{7} = num2str(cortMag.excludeROIs); end
if isfield(cortMag,'templateRoiNum'), def{8} = num2str(cortMag.templateRoiNum); endif isfield(cortMag,'flatDataFlag'),   def{9} = num2str(cortMag.flatDataFlag); end

answer = inputdlg(prompt, 'CortMag Parameters', 1, def, 'on');

if ~isempty(answer)
   cortMag.binDist         = str2num(answer{1});
   cortMag.expNumber       = str2num(answer{2});
   cortMag.stimulusRadius  = str2num(answer{3});
   cortMag.coThresh        = str2num(answer{4});  
   cortMag.fovealPhase     = str2num(answer{5});
   cortMag.peripheralPhase = str2num(answer{6});
   cortMag.excludeROIs     = str2num(answer{7});
   cortMag.templateRoiNum  = str2num(answer{8});   cortMag.flatDataFlag    = str2num(answer{9});
else
   cortMag = 0;
end

return;