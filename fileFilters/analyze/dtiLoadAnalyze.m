function dtiLoadAnalyze(hObject,handles)
%
%
%
%
%

disp('Select the vecX, vecY, vecZ, FA and B0 images.');
[f, p] = uigetfile({'*.hdr','Analyze 7.5 format (*.hdr)'}, 'Select X-vector file...');
[handles.vec.img(:,:,:,1), handles.vec.mmPerVoxel, hdr] = loadAnalyze(fullfile(p,f));
handles.dataDir = p;
if(~isempty(hdr.descrip))
    tmp = findstr(hdr.descrip,';'); 
    if(isempty(tmp)) handles.subName = hdr.descrip;
    else handles.subName = hdr.descrip(1:tmp(1)-1); end
else
    handles.subName = fileparts(fileparts(p));
end
handles.vec.img(:,:,:,1) = handles.vec.img(:,:,:,1).*hdr.pinfo(1);
[tmp,fname]=fileparts(f);
handles.title = ['mrDFT: ',fname];
set(gcbf,'Name',handles.title);
ii = findstr(f, 'vecX.hdr');
if(~isempty(ii))
    f = [f(1:ii(end)-1) 'vecY.hdr'];
end
if(isempty(ii) | ~exist(fullfile(p,f), 'file'))
    [f, p] = uigetfile({'*.hdr','Analyze 7.5 format (*.hdr)'}, 'Select Y-vector file...');
end
[handles.vec.img(:,:,:,2), handles.vec.mmPerVoxel, hdr] = loadAnalyze(fullfile(p,f));
handles.vec.img(:,:,:,2) = handles.vec.img(:,:,:,2).*hdr.pinfo(1);
if(~isempty(ii))
    f = [f(1:ii(end)-1) 'vecZ.hdr'];
end
if(isempty(ii) | ~exist(fullfile(p,f), 'file'))
    [f, p] = uigetfile({'*.hdr','Analyze 7.5 format (*.hdr)'}, 'Select Z-vector file...');
end
[handles.vec.img(:,:,:,3), handles.vec.mmPerVoxel, hdr] = loadAnalyze(fullfile(p,f));
handles.vec.img(:,:,:,3) = handles.vec.img(:,:,:,3).*hdr.pinfo(1);
handles.vec.mat = hdr.mat;

bgNum = 1;
if(~isempty(ii))
    f = [f(1:ii(end)-1) 'FA.hdr'];
end
if(isempty(ii) | ~exist(fullfile(p,f), 'file'))
    [f, p] = uigetfile({'*.hdr','Analyze 7.5 format (*.hdr)'}, 'Select FA file...');
end
if(~isnumeric(f))
    handles.bg(bgNum).name = 'FA';
    [handles.bg(bgNum).img, handles.bg(bgNum).mmPerVoxel, hdr] = loadAnalyze(fullfile(p,f));
    handles.bg(bgNum).mat = hdr.mat;
    handles.bg(bgNum).img = handles.bg(bgNum).img.*hdr.pinfo(1)./1000;
    bgNum=bgNum+1;
else
    error('FA is necessary!');
end
if(~isempty(ii))
    f = [f(1:ii(end)-1) 'B0.hdr'];
end
if(isempty(ii) | ~exist(fullfile(p,f), 'file'))
    [f, p] = uigetfile({'*.hdr','Analyze 7.5 format (*.hdr)'}, 'Select b0 file...');
end
if(~isnumeric(f))
    handles.bg(bgNum).name = 'b0';
    [handles.bg(bgNum).img, handles.bg(bgNum).mmPerVoxel, hdr] = loadAnalyze(fullfile(p,f));
    handles.bg(bgNum).mat = hdr.mat;
    handles.bg(bgNum).img = handles.bg(bgNum).img.*hdr.pinfo(1);
    % clip the b0
    [count,value] = hist(handles.bg(bgNum).img(:),100);
    clipVal = value(min(find(cumsum(count)./sum(count)>=0.99)));
    handles.bg(bgNum).img(handles.bg(bgNum).img>clipVal) = clipVal;
    handles.bg(bgNum).img = handles.bg(bgNum).img./max(handles.bg(bgNum).img(:));
    bgNum = bgNum+1;
end
% Set defaults so that we can hobble along without a proper ac-pc aligned
% T1.
handles.talXform = eye(4);
handles.acpcXform = eye(4);
if(~isempty(ii))
    f = [f(1:ii(end)-1) 't1anat.hdr'];
end
if(isempty(ii) | ~exist(fullfile(p,f), 'file'))
    [f, p] = uigetfile({'*.hdr','Analyze 7.5 format (*.hdr)'}, 'Select T1 file...');
end
if(~isnumeric(f))
    handles.bg(bgNum).name = 't1';
    [handles.bg(bgNum).img, handles.bg(bgNum).mmPerVoxel, hdr] = loadAnalyze(fullfile(p,f));
    % VICIOUS HACK to make this code work with SPM-style hdr.mat format.
    % Note the hard-coded scale factor (2). :O
    for(ii=1:bgNum-1)
        handles.bg(ii).mat = [eye(3), (handles.bg(ii).mat(1:3,4)-hdr.mat(1:3,4))/2; 0 0 0 1];
    end
    handles.vec.mat = handles.bg(1).mat;

    % This file's xform matrix should take us into pseudo-talairach space.
    handles.talXform = hdr.mat;
    handles.acpcXform = handles.talXform;
    handles.bg(bgNum).mat = eye(4);
    handles.bg(bgNum).img = handles.bg(bgNum).img.*hdr.pinfo(1);
    % clip
    [count,value] = hist(handles.bg(bgNum).img(:),256);
    clipVal = value(min(find(cumsum(count)./sum(count)>=0.985)));
    handles.bg(bgNum).img(handles.bg(bgNum).img>clipVal) = clipVal;
    clipVal = value(max(find(cumsum(count)./sum(count)<=0.4)));
    handles.bg(bgNum).img(handles.bg(bgNum).img<clipVal) = clipVal;
    handles.bg(bgNum).img = handles.bg(bgNum).img-clipVal;
    handles.bg(bgNum).img = handles.bg(bgNum).img./max(handles.bg(bgNum).img(:));
    bgNum = bgNum+1;
end

% The data are unit-vector floats 
% Transform images to conform to the standard:
% 1st dim should be Talairach X- left/right
% 2nd dim should be Talairach Y- anterior/posterior
% 3rd dim should be Talairach Z- inferior/superior
set(handles.popupBackground, 'String', {handles.bg.name, 'vectorRGB'});
handles.curImgSize = size(handles.bg(1).img);
handles.curXform = handles.acpcXform;
handles.curMmPerVoxel = handles.bg(1).mmPerVoxel;
handles = handtiRefreshFigure(handles);
guidata(hObject, handles);
return;
