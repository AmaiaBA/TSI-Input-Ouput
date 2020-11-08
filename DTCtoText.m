function [rearrDM,DataPoints,NrOfChannels ] = DTCtoText(NTCFile,TXTFile)

% This function extracts residuals time course from binary files

% Input:
% - NTCFile: .ntc file name
% - TXTFile: .txt filename 

% Output:
% - rearrDM : rearranged Design Matrices. Cell matrix of dimensions: NrOfChannels x NrOfHbType (usually 3: HbO, HbR, HbT)
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
NrOfPredictors =  fread(fileIDBin,[1],'uint32');
fprintf(fileIDTxT,'NrOfPredictors: \t%i\n',NrOfPredictors);
DataPoints =  fread(fileIDBin,[1],'uint32');
fprintf(fileIDTxT,'DataPoints: \t%i\n',DataPoints);

NrOfHbTypes = 3;
fprintf(fileIDTxT,'\n');
Data = fread(fileIDBin,[NrOfChannels*NrOfPredictors*DataPoints*NrOfHbTypes],'double');
rearrDM = cell(NrOfChannels,NrOfHbTypes); % preallocation of dattapoints
cs_ChanDPoints =[0; cumsum(repmat((repelem(DataPoints,NrOfChannels)')*NrOfPredictors, [NrOfHbTypes,1]))]; % create index array 

counter = 0;
totalTP = 0;
for hh=1:NrOfHbTypes % for each hb type
   for cc=1:NrOfChannels
       counter = counter +1;
       rearrDM{cc,hh} = Data(cs_ChanDPoints(counter)+1:cs_ChanDPoints(counter+1));  
       totalTP = totalTP + numel(Data(cs_ChanDPoints(counter)+1:cs_ChanDPoints(counter+1)));
   end    
end

for hh=1:NrOfHbTypes
    for cc=1:NrOfChannels
        temp = rearrDM{cc,hh};
        rearrDM{cc,hh} = reshape(temp,[numel(temp)/NrOfPredictors, NrOfPredictors]);

    end
end

fclose(fileIDTxT);

end
