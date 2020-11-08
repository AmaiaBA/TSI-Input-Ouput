function [ntcDataPoints, ntcData]=readNTCFile(NTCPath, NTCFile)
% this function extracts information from ntc file
% input: ntc fileName (with .ntc extension) and path
% output:
%   ntcDataPoints: total # of frames or data points of timecourse
%   ntcData: Data timecourse. It has dimensions: (nrChannels*3 [due to HbO HbR and HbT]) x  ntcDataPoints

% Author: M.L & A.B., Maastricht University
% Last edited: 22.01.2019
%%

fileIDBin = fopen(fullfile(NTCPath,NTCFile));
fileversion = fread(fileIDBin,[1], 'uint16');
NrOfSources = fread(fileIDBin,[1],'uint32');
NrOfDetectors = fread(fileIDBin,[1],'uint32');
ntcDataPoints = fread(fileIDBin,[1],'uint32');
NrOfHbTypes = 3;
ntcData = fread(fileIDBin,[ntcDataPoints NrOfDetectors*NrOfSources*NrOfHbTypes], 'double');


