function [wl1, wl2, masked_wl1, masked_wl2]=readWLData(filePath,fileName,Masked_Channels,NrUnMasked_Channels, NrOfChannels)

% Input
% FilePath: hdr file path
% FileName: hdr file name
% pos_unMaskedChan: position of channels we are measuring from
% UnMasked_Channels: number of channels we are measuring from

% Output
% wl1/wl2: unprunned wl1 and wl2 matrices
% masked_wl1/ masked_wl2: prunned wl1 and wl2 matrices

fid = fopen(fullfile(filePath,[fileName(1:end-4) '.wl1']),'rt');
tmp = textscan(fid,'%s','Delimiter','\n');
mtrx = tmp{:};
% wl1 = zeros(size(mtrx,1),NrOfChannels);
% for int=1:size(mtrx,1)
%     wl1(int,:)= str2num(cell2mat(mtrx(int))); 
% end
% wl1 = str2num(cell2mat(mtrx));
wl1 = str2num(cell2mat(mtrx));

fid = fopen(fullfile(filePath,[fileName(1:end-4) '.wl2']),'rt');
tmp = textscan(fid,'%s','Delimiter','\n');
mtrx = tmp{:};
wl2 = str2num(cell2mat(mtrx));
% wl2 = zeros(size(mtrx,1),NrOfChannels);
% for int=1:size(mtrx,1)
%     wl2(int,:)= str2num(cell2mat(mtrx(int))); 
% end
temp = 1:NrOfChannels;
tempMaskedChan = Masked_Channels<=NrOfChannels;

pos_unMaskedChan = find(ismember(temp,Masked_Channels(tempMaskedChan))==0);

masked_wl1 = wl1(:,pos_unMaskedChan(1:(NrUnMasked_Channels/3)));
masked_wl2 = wl2(:,pos_unMaskedChan(1:(NrUnMasked_Channels/3))); 
