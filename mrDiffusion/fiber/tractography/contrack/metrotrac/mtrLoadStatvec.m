function [statvec] = mtrLoadStatvec(in_filename)

fid = fopen(in_filename,'r');

numP = fread(fid, 1, 'int');
statvec = fread(fid,numP,'double');

fclose(fid);