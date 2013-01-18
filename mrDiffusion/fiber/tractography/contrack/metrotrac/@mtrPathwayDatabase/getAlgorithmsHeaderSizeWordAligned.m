function s = getAlgorithmsHeaderSizeWordAligned(this)

% Assume a word is 4 bytes
s = getAlgorithmsHeaderSize(this);
s = ceil(s/4)*4;