function [NrOfSources, NrOfDetectors, NrOfChannels, SamplingRate, sd_ind, Masked_Channels,NrUnMasked_Channels, prt_info, GainValMat, deviceType,NSversion,NrOfSDD, SDindx]= HDRFile_extractInfo(filePath, fileName)
% This function extracts information from the header file

% Input : hdr file name (with .hdr extension) and hdrPath 
% Output : 
%   NrOfSources
%   NrOfDetectors 
%   NrOfChannels
%   SamplingRate (in Hz)
%   sd_ind: source detector index matrix ( ones and zeros; ones = source detector pair used during measurement, zeros = not)
%   Masked_Channels (channels that are NOT in use)
%   NrUnMasked_Channels (channels thare are used)
%   prt_info ( trigger summary [seconds trigger_code frames])
%   Gain Values Matrix


% Author: M.L & A.B., Maastricht University
% Last edited: 22.01.2019
%%
hdr_dir = dir([filePath '/*.hdr']);
if isempty(hdr_dir)
    error('ERROR: Cannot find NIRx header file in selected directory...');
end
% hdr_name =  fileName; %hdr_dir(1).name;
fid = fopen(fullfile(filePath,fileName));%[NIRx_foldername '/' hdr_name]);
tmp = textscan(fid,'%s','delimiter','\n');%This just reads every line
hdr_str = tmp{1};
fclose(fid);

%Find number of sources
keyword = 'Sources=';
tmp = strfind(hdr_str,keyword);
tmp = hdr_str{(~cellfun(@isempty,tmp))};
NrOfSources = str2double(tmp(length(keyword)+1:end));

%Find number of sources
keyword = 'Detectors=';
tmp = strfind(hdr_str,keyword);
tmp = hdr_str{~cellfun(@isempty,tmp)};
NrOfDetectors = str2num(tmp(length(keyword)+1:end));

% calculate number of channels
NrOfChannels = NrOfSources * NrOfDetectors;

%Find Sample rate
keyword = 'SamplingRate=';
tmp = strfind(hdr_str,keyword);
tmp = hdr_str{~cellfun(@isempty,tmp)};
SamplingRate = str2num(tmp(length(keyword)+1:end));

keyword = 'Events=#';
tmp = strfind(hdr_str,keyword);
ind = find(~cellfun(@isempty,tmp)) + 1; %This gives cell of hdr_str with keyword
if isempty(ind)
    keyword = 'Events="#';
    tmp = strfind(hdr_str,keyword);
    ind = find(~cellfun(@isempty,tmp)) + 1; %This gives cell of hdr_str with keyword
    if isempty(ind)
        error('ERROR: Cannot find the S-D-Mask field in the header file...');
    end
end
tmp = strfind(hdr_str(ind+1:end),'#');
ind2 = find(~cellfun(@isempty,tmp)) - 1;
ind2 = ind + ind2(1);
sd_ind = cell2mat(cellfun(@str2num,hdr_str(ind:ind2),'UniformOutput',0));
seconds = sd_ind(:,1);
triggers = sd_ind(:,2);
frames = sd_ind(:,3);
prt_info = [seconds,triggers,frames];

keyword = 'S-D-Mask=#';
tmp = strfind(hdr_str,keyword);
ind = find(~cellfun(@isempty,tmp)) + 1; %This gives cell of hdr_str with keyword
if isempty(ind)
    keyword = 'S-D-Mask="#';
    tmp = strfind(hdr_str,keyword);
    ind = find(~cellfun(@isempty,tmp)) + 1; %This gives cell of hdr_str with keyword
    if isempty(ind)
        error('ERROR: Cannot find the S-D-Mask field in the header file...');
    end
end
tmp = strfind(hdr_str(ind+1:end),'#');
ind2 = find(~cellfun(@isempty,tmp)) - 1;
ind2 = ind + ind2(1);
sd_ind = cell2mat(cellfun(@str2num,hdr_str(ind:ind2),'UniformOutput',0))';
Masked_Channels = find(sd_ind(:)==0);

% extract the UnMasked Channels
Masked_Channels = [Masked_Channels;Masked_Channels+NrOfChannels; Masked_Channels+NrOfChannels*2];
NrUnMasked_Channels = NrOfChannels*3 - length(Masked_Channels);

keyword = 'Gains=';
tmp = strfind(hdr_str,keyword);
ind = find(~cellfun(@isempty,tmp)) + 1;
tmp = strfind(hdr_str(ind+1:end),'#');
ind2 = find(~cellfun(@isempty,tmp)) - 1;
ind2 = ind + ind2(1);
GainValMat = cell2mat(cellfun(@str2num,hdr_str(ind:ind2),'UniformOutput',0));

keyword = 'Device=';
tmp = strfind(hdr_str,keyword);
ind = find(~cellfun(@isempty,tmp)); %This gives cell of hdr_str with keyword
if strcmp(hdr_str{ind},'Device="NIRSport 8x8"')
    deviceType = 'Device="NIRSport 8x8"';
elseif  strcmp(hdr_str{ind},'Device="NIRScout 16x24"')
    deviceType = 'Device="NIRScout 16x24"';
end

%Extract NirStar version
keyword = 'NIRStar=';
tmp = strfind(hdr_str,keyword);
ind = find(~cellfun(@isempty,tmp)); %This gives cell of hdr_str with keyword
NSversion = str2double(hdr_str{ind}(length(keyword)+2:end-1));

%Were SDC used?
if NSversion>=15.0
    if NSversion==15.0
        keyword = 'ShortDetectors=';
    else
        keyword = 'ShortBundles=';
    end
    tmp = strfind(hdr_str,keyword);
    ind = find(~cellfun(@isempty,tmp)); %This gives cell of hdr_str with keyword
    tmp = strfind(hdr_str{ind},'=');
    NrOfSDD = str2double(hdr_str{ind}(tmp+1:end));
    if NrOfSDD>0 && NSversion>15.0
        keyword_SDC = 'ShortDetIndex="';
        tmpStartSDC = strfind(hdr_str,keyword_SDC);
        ind = find(~cellfun(@isempty,tmpStartSDC));
        tmp = find(isspace(hdr_str{ind})==1);
        SDindx = zeros(8*NrOfSDD,1);
        counter = numel(keyword_SDC);
        for int=1:numel(tmp)
            SDindx(int) = str2num(hdr_str{ind}(counter+1:tmp(int)-1));
            counter = tmp(int);
        end
        SDindx(int+1) = SDindx(int)+1;
    else
        SDindx = [];
        
    end
        
else
    NrOfSDD = 0;   
    SDindx = [];
end

end

