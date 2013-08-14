function mrAnatSetNiftiXform(niftiFile, outFile);
%
% mrAnatSetNiftiXform([niftiFile=uigetfile],[outFile=uiputfile])
%
% Allows you to set the qto xform in a nifti file.
%
% REQUIRES:
%  * Stanford anatomy tools (eg. /usr/local/matlab/toolbox/mri/Anatomy)
%
% HISTORY:
% 2006.10.25 RFD (bob@white.stanford.edu) wrote it.

if (~exist('niftiFile','var') || isempty(niftiFile))
    [f,p] = uigetfile({'*.nii.gz','NIFTI';'*.*', 'All Files (*.*)'}, 'Select NIFTI file...');
    if(isnumeric(f)) disp('User canceled.'); return; end
    niftiFile = fullfile(p,f);
end

ni = niftiRead(niftiFile);
ni = niftiApplyCannonicalXform(ni);
img = mrAnatHistogramClip(double(ni.data), 0.4, 0.98);

nii.img = img;
nii.hdr.dime.pixdim = [1 ni.pixdim 1 1 1 1];
nii.hdr.dime.datatype = 64;
nii.hdr.dime.dim = [3 size(nii.img) 1 1 1 1];
%nii.hdr.hist.originator = [round(ni.qto_ijk(1:3,:)*[0 0 0 1]')'+1 128 0];
nii.hdr.hist.originator = [round(size(nii.img)./2) 128 0];
h = figure('unit','normal','pos', [0.18 0.08 0.5 0.85],'name','Set AC-PC landmarks');
opt.setarea = [0.05 0.15 0.9 0.8];
opt.usecolorbar = 0;
opt.usestretch = 0;
opt.command = 'init';
view_nii(h, nii, opt);
%d = getappdata(h);
hstr = num2str(h);
cb = ['d=getappdata(' hstr ');p=d.nii_view.imgXYZ.vox;setappdata(' hstr ',''ac'',p);set(gcbo,''String'',[''AC=['' num2str(p) '']'']);'];
b1 = uicontrol(h, 'Style','pushbutton','Visible','on','String','Set AC','Position',[20 30 150 30],'Callback',cb);
cb = ['d=getappdata(' hstr ');p=d.nii_view.imgXYZ.vox;setappdata(' hstr ',''pc'',p);set(gcbo,''String'',[''PC=['' num2str(p) '']'']);'];
b2 = uicontrol(h, 'Style','pushbutton','Visible','on','String','Set PC','Position',[190 30 150 30],'Callback',cb);
cb = ['d=getappdata(' hstr ');p=d.nii_view.imgXYZ.vox;setappdata(' hstr ',''ms'',p);set(gcbo,''String'',[''MidSag=['' num2str(p) '']'']);'];
b3 = uicontrol(h, 'Style','pushbutton','Visible','on','String','Set MidSag','Position',[360 30 150 30],'Callback',cb);
cb = ['setappdata(' hstr ',''done'',1);'];
b4 = uicontrol(h, 'Style','pushbutton','Visible','on','String','FINISH','Position',[530 30 80 30],'Callback',cb);
done = false;
while(~done)
    d = getappdata(h);
    if(isfield(d,'ac')&&isfield(d,'pc')&&isfield(d,'ms')&&isfield(d,'done')&&d.done==1)
        done = true;
        %convert matlab 1-based indices to zero-indexed indices
        %alignLandmarks = [d.ac; d.pc; d.ms]-1;
        alignLandmarks = [d.ac; d.pc; d.ms];
    end
    pause(.1);
end
close(h);

%disp(alignLandmarks);
origin = alignLandmarks(1,:);
% Define the current image axes by re-centering on the origin (the AC)
imY = alignLandmarks(2,:)-origin; imY = imY./norm(imY);
imZ = alignLandmarks(3,:)-origin; imZ = imZ./norm(imZ);
imX = cross(imZ,imY);
% Make sure the vectors point right, superior, anterior
if(imX(1)<0) imX = -imX; end
if(imY(2)<0) imY = -imY; end
if(imZ(3)<0) imZ = -imZ; end
% Project the current image axes to the cannonical AC-PC axes. These
% are defined as X=[1,0,0], Y=[0,1,0], Z=[0,0,1], with the origin
% (0,0,0) at the AC. Note that the following are the projections
x = [0 1 imY(3)]; x = x./norm(x);
y = [1  0 imX(3)]; y = y./norm(y);
%z = [0  imX(2) 1]; z = z./norm(z);
z = [0  -imY(1) 1]; z = z./norm(z);
% Define the 3 rotations using the projections. We have to set the sign
% of the rotation, depending on which side of the plane we came from.
rot(1) = sign(x(3))*acos(dot(x,[0 1 0])); % rot about x-axis (pitch)
rot(2) = sign(y(3))*acos(dot(y,[1 0 0])); % rot about y-axis (roll)
rot(3) = sign(z(2))*acos(dot(z,[0 0 1])); % rot about z-axis (yaw)

scale = ni.pixdim;
% Affine build assumes that we need to translate before rotating. But,
% our rotations have been computed about the origin, so we'll pass a
% zero translation and set it ourselves (below).
im2tal = affineBuild([0 0 0], rot, scale, [0 0 0]);
tal2im = inv(im2tal);

% Insert the translation.
%tal2im(1:3,4) = [origin+scale/2]';
tal2im(1:3,4) = [origin]';
im2tal = inv(tal2im);

if (~exist('outFile','var') || isempty(outFile))
    outFile = niftiFile;
end
resp = questdlg(['Save new transform matrix in ' outFile '?'],'Save confirmation','Ok','Cancel','Ok');
if(strcmpi(resp,'cancel'))
    disp('user canceled- transform NOT saved.');
    return;
end
if(exist(outFile,'file'))
    clear ni;
    ni = niftiRead(outFile);
    ni = niftiApplyCannonicalXform(ni);
else
    ni.fname = outFile;
end
ni = niftiSetQto(ni,im2tal,true);
% NOTE: our data are always left-handed (ie. 'neurological;
% unflipped; left-is-left). So, we force the qfac to reflect
% that.
ni.qfac = 1;

writeFileNifti(ni);
disp('transform saved.');
return;
