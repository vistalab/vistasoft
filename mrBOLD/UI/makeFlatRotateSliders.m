function vw = makeFlatRotateSliders(vw)
%
% vw = makeFlatRotateSliders(vw)
%
% Installs push buttons that rotate image.
%
% djh, 1/97

% Slider callback

vw = makeSlider(vw,'ImageRotate',[0,2*pi],[.5,.03,.2,.05]);

return;

