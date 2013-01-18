function a = dtiGetAlgoHeaderSizeWordAligned()
% Assume a word is 4 bytes

a = dtiGetAlgoHeaderSize();
a = ceil(a/4)*4;