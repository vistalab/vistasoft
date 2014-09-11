%% bookkeeping for retinotopy and words analysis

%% name of sessions, abbreviations, and their paths
% TODO: probably have to do some moving around

% list_session = {
%     'ak090303'        % 1
%     'amr081030'       % 2
%     'ch100805'        % 3
%     'kh100421'        % 4
%     'kw100407'        % 5
%     'lmp090722'       % 6
%     'ni100312'        % 7
%     'rb081009'        % 8 
%     'wg100416'        % 9
%     'rl20140507'      % 10
%     'am20140522'      % 11
%     'ar20140527'      % 12
%     };


%     [num2str(list_sessionPath{1})  ]             % ak     1
%     [num2str(list_sessionPath{2})  ]             % amr    2
%     [num2str(list_sessionPath{3})  ]             % ch     3
%     [num2str(list_sessionPath{4})  ]             % kh     4
%     [num2str(list_sessionPath{5})  ]             % kw     5
%     [num2str(list_sessionPath{6})  ]             % lmp    6
%     [num2str(list_sessionPath{7})  ]             % ni     7
%     [num2str(list_sessionPath{8})  ]             % rb     8
%     [num2str(list_sessionPath{9})  ]             % wg     9
%     [num2str(list_sessionPath{10}) ]             % rl     10
%     [num2str(list_sessionPath{12}) ]             % am     11
%     [num2str(list_sessionPath{11}) ]             % asr    12
%     };

list_sub = {
    'ak'    % 1
    'amr'   % 2
    'ch'    % 3
    'kh'    % 4
    'kw'    % 5
    'lmp'   % 6
    'ni'    % 7
    'rb'    % 8
    'wg'    % 9
    'rl'    % 10
    'am'    % 11
    'asr'   % 12
    };


list_sessionPath = {
    '/biac4/wandell/biac3/wandell7/data/Words/vwfaLoc/ak/ak090303/'                 % ak
    '/biac4/wandell/biac3/wandell7/data/Words/vwfaLoc/amr/amr081030/'               % amr
    '/biac4/wandell/biac3/wandell7/data/Words/vwfaLoc/ch/ch100805/'                 % ch
    '/biac4/wandell/biac3/wandell7/data/Words/vwfaLoc/kh/kh100421/'                 % kh
    '/biac4/wandell/biac3/wandell7/data/Words/vwfaLoc/kw/kw100407/'                 % kw
    '/biac4/wandell/biac3/wandell7/data/Words/vwfaLoc/lmp/lmp090722/'               % lmp
    '/biac4/wandell/biac3/wandell7/data/Words/vwfaLoc/ni/ni100312/'                 % ni
    '/biac4/wandell/biac3/wandell7/data/Words/vwfaLoc/rb/rb081009/'                 % rb
    '/biac4/wandell/biac3/wandell7/data/Words/vwfaLoc/wg/wg100416/'                 % wg
    '/biac4/wandell/data/reading_prf/rosemary/20140818_1211/'                       % rl
    '/biac4/wandell/data/reading_prf/aviv/20140522_1015/vwfaLocalizer/'             % am
    '/biac4/wandell/data/reading_prf/ariel/20140527_standardized/'                  % asr
};


%% mesh names and path
list_meshL = {
    'leftMesh_inflate400.mat'           % ak
    'leftSmooth_inflate400.mat'         % amr
    'leftMesh_inflate400.mat'           % ch
    'leftMesh_inflate400.mat'           % kh
    'mesh_leftSmooth_inflate400.mat'    % kw
    'leftSmooth_inflate400.mat'         % lmp
    'left_mesh2_inflate400.mat'         % ni
    'leftSmooth_inflate400.mat'         % rb
    'mesh_leftSmooth_inflate400.mat'    % wg
    'left_inflated_400.mat'             % rl
    'leftSmooth_inflated.mat'           % am
    'lh_inflated400.mat'                % asr
    };

list_meshR = {
    'rightMesh_inflate.mat'             % ak
    'rightSmooth_inflate400.mat'        % amr
    'rightMesh_inflate400.mat'          % ch
    'rightMesh_inflate400.mat'          % kh
    'mesh_rightSmooth_inflate400.mat'   % kw
    'rightSmooth_inflate400.mat'        % lmp
    'mesh_rightSmooth_inflate400.mat'   % ni
    'rightSmooth_inflate400.mat'        % rb
    'mesh_rightSmooth_inflate400.mat'   % wg
    'right_inflated_400.mat'            % rl
    'rightSmooth_inflated.mat'          % am
    'rh_inflated400.mat'                % asr
    };

list_meshPath = {
    '/biac4/wandell/biac2/wandell2/data/anatomy/kevan/Anatomy_1mm_resolution/'  % ak
    '/biac4/wandell/biac2/wandell2/data/anatomy/rauschecker/Anatomy081031/'     % amr
    '/biac4/wandell/biac3/wandell7/data/Words/vwfaLoc/ch/ch100805/3DAnatomy/'   % ch
    '/biac4/wandell/biac3/wandell7/data/Words/vwfaLoc/kh/kh100421/3DAnatomy/'   % kh
    '/biac4/wandell/biac3/wandell7/data/Words/vwfaLoc/kw/kw100407/3DAnatomy/'   % kw
    '/biac4/wandell/biac2/wandell2/data/anatomy/perry/1mmResample/'             % lmp
    '/biac4/wandell/biac3/wandell7/data/Words/vwfaLoc/ni/ni100312/3DAnatomy/'   % ni
    '/biac4/wandell/biac3/wandell7/data/Words/vwfaLoc/rb/rb081009/3DAnatomy/'   % rb
    '/biac4/wandell/biac3/wandell7/data/Words/vwfaLoc/wg/wg100416/3DAnatomy/'   % wg
    '/biac4/wandell/data/anatomy/rosemary/mesh/'                                % rl
    '/biac4/wandell/data/anatomy/mezer/'                                        % am
    '/biac4/wandell/data/anatomy/rokem/t1/mesh/'                                % asr
    };

%% prfModels: their names and which dataType they are in

list_retModName = {
     'rmImported_retModel-20100713-161648-fFit.mat'             % ak
     'rmImported_retModel-20090827-124025-fFit.mat'             % amr
     'rmImported_retModel-20100819-150942-fFit.mat'             % ch
     'rmImported_retModel100911-20100714-110024-fFit.mat'       % kh
     'rmImported-retModel-8Bars-ret14-20090426-fFit.mat'        % kw
     'rmImported_retModel-8Bars-ret14-20090426-fFit.mat'        % lmp
     'ImportedRet_ni_8bars.mat'                                 % ni
     'rmImported_retModel-8Bars-ret14-fFit.mat'                 % rb
     'rmImported_retModel-20100519-152019-fFit.mat'             % wg
     'retModel-20140824-011024-fFit.mat'                        % rl
     'rmImported_retModel-20140713-182325-fFit'                 % am
     'rmImported_retModel-20110915-121938-fFit-fFit-fFit.mat'   % asr
    };

list_retModFolderPath = {
    [num2str(list_sessionPath{1}) 'Gray/GLMs/']             % ak
    [num2str(list_sessionPath{2}) 'Gray/GLMs/']             % amr
    [num2str(list_sessionPath{3}) 'Gray/GLMs/']             % ch
    [num2str(list_sessionPath{4}) 'Gray/GLMs/']             % kh
    [num2str(list_sessionPath{5}) 'Gray/GLMs/']             % kw
    [num2str(list_sessionPath{6}) 'Gray/GLMs/']             % lmp
    [num2str(list_sessionPath{7}) 'Gray/GLMs/']             % ni
    [num2str(list_sessionPath{8}) 'Gray/GLMs/']             % rb
    [num2str(list_sessionPath{9}) 'Gray/GLMs/']             % wg
    [num2str(list_sessionPath{10}) 'Gray/AveragesBars/']    % rl
    [num2str(list_sessionPath{11}) 'Gray/GLMs/']            % am
    [num2str(list_sessionPath{12}) 'Gray/GLMs/']            % asr

    };

%% GLMS paths  

list_glmFolderPath = cell(length(list_sessionPath),1);
for ii = 1:length(list_glmFolderPath)
   list_glmFolderPath{ii} = [num2str(list_sessionPath{ii}) 'Gray/GLMs/'];  
end


%% roi local paths
list_roiLocalPath = {
    [num2str(list_sessionPath{1}) 'Gray/ROIs/']             % ak
    [num2str(list_sessionPath{2}) 'Gray/ROIs/']             % amr
    [num2str(list_sessionPath{3}) 'Gray/ROIs/']             % ch
    [num2str(list_sessionPath{4}) 'Gray/ROIs/']             % kh
    [num2str(list_sessionPath{5}) 'Gray/ROIs/']             % kw
    [num2str(list_sessionPath{6}) 'Gray/ROIs/']             % lmp
    [num2str(list_sessionPath{7}) 'Gray/ROIs/']             % ni
    [num2str(list_sessionPath{8}) 'Gray/ROIs/']             % rb
    [num2str(list_sessionPath{9}) 'Gray/ROIs/']             % wg
    [num2str(list_sessionPath{10}) 'Gray/ROIs/']            % rl
    [num2str(list_sessionPath{11}) 'Gray/ROIs/']            % am
    [num2str(list_sessionPath{12}) 'Gray/ROIs/']            % asr
    };

%% whether or not prf coverage needs to be flipped over x-axis when using 
% rmPlotCoveragefromROImatfile.m (i.e. flip the y-values)
% point of confusion: flipping seems to be different when using rmPlotCoveragefromROImatfile.m
% versus rmPlotCoverage

list_YNflipYvalues = [
    0;  % 'ak'    % 1
    0;  % 'amr'   % 2
    0;  % 'ch'    % 3
    0;  % 'kh'    % 4
    0;  % 'kw'    % 5
    0;  % 'lmp'   % 6
    0;  % 'ni'    % 7
    1;  % 'rb'    % 8
    0;  % 'wg'    % 9
    0;  % 'rl'    % 10
    0;  % 'am'    % 11
    0;  % 'asr'   % 12
    ]; 