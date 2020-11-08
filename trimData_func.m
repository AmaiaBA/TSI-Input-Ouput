
function trimData_func(filePath,fileName,triggerInfo,tStart,tEnd,newPath)

% This function trims .hdr, .wl and .evt files, saves them and creates a new prt file
% It assumes that the first trigger is a rest trigger

% Input : 
%   filePath: path to hdr file 
%   fileName: hdr file name (with .hdr extension)
%   triggerInfo: structure with fields:
%       .restTrigger: trigger ID for rest condition [integer]
%       .taskTrigger: trigger ID(s) for task condition(s) [integer]
%   tStart: start time (s) of the run; if empty - first trigger is considered
%   tEnd: end time (s) of the run; if empty - last trigger + 15s is considered
%   lastRestDuration: last rest period duration [in seconds]
%   newPath: path to save newly created files

% Output : 
%   _trim.hdr
%   _trim.wl1 || _trim.wl2
%   _trim.prt
%   _trim.evt

%%% dependencies:
% HDRFile_extractInfo.m
% readWLData.m
% this function uses NeuroElf functions, version: v09d --> http://neuroelf.net/

%%%%%%%

% load .hdr and .wl files
[~, ~, NrOfChannels, SamplingRate, ~, Masked_Channels,NrUnMasked_Channels, prt_info, ~, ~,~,~, ~]= HDRFile_extractInfo(filePath, fileName);
[wl1, wl2, ~, ~]=readWLData(filePath,fileName,Masked_Channels,NrUnMasked_Channels, NrOfChannels);

if ~isempty(tStart)
    startPoint = ceil(tStart*SamplingRate); % first trigger
else
    startPoint = prt_info(1,3); % first trigger
end
if ~isempty(tEnd)
    endPoint = ceil(tEnd*SamplingRate);
else
    endPoint = ceil(15*SamplingRate)+prt_info(end,3);
end

new_prtInfo  = prt_info;
new_prtInfo(:,3) = new_prtInfo(:,3)-(repelem(startPoint-1,numel(new_prtInfo(:,3))))';
new_prtInfo(:,1) = new_prtInfo(:,1) - repelem((new_prtInfo(1,1) - (1/SamplingRate)),numel(new_prtInfo(:,1)))';

% create prt file
cd(newPath)
createPRTfromHDRFile_func(SamplingRate,new_prtInfo,newPath,fileName,triggerInfo,lastRestDuration)%has 6 input arguments but needs 5
cd(filePath)
newWL1 = wl1(startPoint:endPoint,:);
newWL2 = wl2(startPoint:endPoint,:);

% save wl data

dlmwrite(fullfile(newPath,[fileName(1:end-4) '_trim.wl1']),newWL1,'delimiter',' ');
dlmwrite(fullfile(newPath, [fileName(1:end-4) '_trim.wl2']),newWL2,'delimiter',' ');

% modify hdr file (events section)

fid = fopen(fullfile(filePath,fileName));%[NIRx_foldername '/' hdr_name]);
tmp = textscan(fid,'%s','delimiter','\n');%This just reads every line
hdr_str = tmp{1};
fclose(fid);

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


for int=0:(ind2-ind)
    tempArr = new_prtInfo(int+1,:);
    tempStr = [num2str(tempArr(1)) char(9) num2str(tempArr(2)) char(9) num2str(tempArr(3))];
    hdr_str{ind+int} = tempStr;
    
end

% save new hdr file
cd(newPath)
filePh = fopen([fileName(1:end-4) '_trim.hdr'],'w');
for int=1:size(hdr_str,1)
    fprintf(filePh,'%s\r\n',hdr_str{int});    
end
fclose(filePh);

% modify .evt data

fileName = [fileName(1:end-4) '.evt'];
evt = load(fullfile(filePath,fileName));
evt(:,1) = prt_info(:,3);
save(fullfile(filePath,[fileName(1:end-4) '_trim.evt']),'evt');     
