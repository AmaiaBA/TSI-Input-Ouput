function [rearrResid,DataPoints,NrOfChannels ]=RTCtoText(NTCFile,TXTFile)

% This function extracts residuals time course from binary files

% Input:
% - NTCFile: .ntc file name
% - TXTFile: .txt filename 

% Output:
% - rearrResid : rearranged residuals. Cell matrix of dimensions: NrOfChannels x NrOfHbType (usually 3: HbO, HbR, HbT)
% - DataPoints: time course length (integer)
% - NrOfChannels


% Last modified: 22.07.2019
% @ authors: M.L & A.B, Maastricht University

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fileIDBin = fopen(NTCFile);
fileIDTxT = fopen(TXTFile,'w');

fileversion =  fread(fileIDBin,[1],'uint16');
fprintf(fileIDTxT,'FileVersion: \t%i\n',fileversion);
NrOfChannels =  fread(fileIDBin,[1],'uint32');
fprintf(fileIDTxT,'NrOfChannels: \t%i\n',NrOfChannels);
DataPoints =  fread(fileIDBin,[1],'uint32');
fprintf(fileIDTxT,'DataPoints: \t%i\n',DataPoints);

fprintf(fileIDTxT,'\n');
NrOfHbTypes = 3;
resid_tc = fread(fileIDBin,NrOfChannels*DataPoints*NrOfHbTypes,'double'); % correct
rearrResid = cell(NrOfChannels,NrOfHbTypes); % prealocation of dattapoints
cs_ChanDPoints =[0; cumsum(repmat((repelem(DataPoints,NrOfChannels)'), [NrOfHbTypes,1]))]; % create index array 


counter = 0;
% totalTP = 0;
for hh=1:NrOfHbTypes % for each hb type
   for cc=1:NrOfChannels
       counter = counter +1;
       rearrResid{cc,hh} = resid_tc(cs_ChanDPoints(counter)+1:cs_ChanDPoints(counter+1));  
%        totalTP = totalTP + numel(resid_tc(cs_ChanDPoints(counter)+1:cs_ChanDPoints(counter+1)));
   end    
end

fclose(fileIDTxT);

end
