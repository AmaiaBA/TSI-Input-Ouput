
function [T,GainValue,CV,SD, CV_decision, masked_wl1, masked_wl2]=ViewDataQuality(filePath,fileName,CV_Thresh)

%%%%%%%%%%%%%%%%
% This function extracts Gain values for each masked channels and
% calculates their coefficient of variation

% Input:
% filePath: path where the header file is located
% fileName: header file name, with extension
% CV_Thresh: threshold for the coefficient of variation [0 100]

% Output:
% T: table with the following fields --> [S D GainValue CV(wl1) CV(wl2) CV decision]
% Gain: channel gain, extracted from the header file
% CV: coefficient of variation
%     > 100*(std(data)/mean(data))
%     > data: wavelength data (wl1, wl2)
%     > dimensions: N x 2, where N = # of channels
%     > dimensions correspond to CV for wl1 and wl2,respectively. 
% CV_decision: 1 if both wl channels survive the CV_Thresh; 0 if not
% SD: source-detector indices, N x 2 matrix

% external functions:
% this function uses 2 additional functions
%           1. HDRFile_extractInfo.m --> extracts information from the header file
%           2. readWLData.m --> loads wavelength data
% have these 2 functions in the same directory as the ViewDataQuality.m

%%%%%%%%%%%%%%%


% load hdr file and wl data

[~, ~, NrOfChannels, ~, sd_ind, Masked_Channels,NrUnMasked_Channels, ~, GainValMat, ~,~,~,~]= HDRFile_extractInfo(filePath, fileName);
[~, ~, masked_wl1, masked_wl2]=readWLData(filePath,fileName,Masked_Channels,NrUnMasked_Channels, NrOfChannels);

% calculate coefficient of variation: it is 100*(1/SNR)

CV = zeros(NrUnMasked_Channels/3,2);
for int=1:NrUnMasked_Channels/3
   CV(int,1) =  100.*(std(masked_wl1(:,int))./mean(masked_wl1(:,int)));
   CV(int,2) =  100.*(std(masked_wl2(:,int))./mean(masked_wl2(:,int)));
end

selCV = [CV(:,1)<=CV_Thresh CV(:,2)<=CV_Thresh];
CV_decision = selCV(:,1).*selCV(:,2);

% GainValue

maskedGainVal = GainValMat'.*logical(sd_ind);
% get index of masked channels
C = setxor(1:NrOfChannels*3,Masked_Channels);
C = C(C<=NrOfChannels);
GainValue = maskedGainVal(C);

% source & detector indices
[D,S] = ind2sub(size(maskedGainVal), C);
SD = [S D];

% save as Table
T = table(S,D,GainValue,CV,CV_decision);


