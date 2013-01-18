function s = getStatisticsHeaderSizeWordAligned(this)

% Assume a word is 4 bytes

s = getStatisticsHeaderSize(this);
s = ceil(s/4)*4;