function [BetaVal, TVal,PVal, channelID]=extractValuesFromGLMtxtFile(hdrFileName,txtFileName, filePath)

% this function takes as input the hdr and glm output files from NIRStar and TSI, respectively and 
% outputs the estimated coefficients, p-values and channel IDs

% Input:
% hdrFileName: name of .hdr file (extension included)
% txtfileName: name of glm output .txt file (extension included)
% filePath: path where both files are located


% Output:
% BetaVal/TVal/PVal:
%   3x1 structure:
%       .HbO - NrChannels x NrCond (excluding rest) 
%       .HbR - NrChannels x NrCond (excluding rest) 
%       .HbT - NrChannels x NrCond (excluding rest) 
%       .Contrast - 4x1 structure:
%           .HbO - NrChannels x NrOfContrasts
%           .HbR - NrChannels x NrOfContrasts
%           .HbT - NrChannels x NrOfContrasts
%           .Name- ContrastNames
% Channel ID: cell matrix with dimension NrChannels x 1


% Dependencies:
% HDRFile_extractInfo.m --> extracts protocol information from hdr file
% based on trigger matrix


% Last updated : 22.07.2019
% @ author: A.B., Maastricht University


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fid = fopen(fullfile(filePath,txtFileName));%[NIRx_foldername '/' hdr_name]);
tmp = textscan(fid,'%s','delimiter','\n');%This just reads every line
GLM_txt = tmp{1};
fclose(fid);

% Load hdr file
[~, ~, ~, ~, ~, ~,~, prt_info, ~, ~,~,NrOfSDD, ~]= HDRFile_extractInfo(filePath, hdrFileName);

% Extract number of tasks
NrOfTasks = size(unique(prt_info(:,2)),1)-1;% remove rest period

% Initialize variables

BetaVal.HbO = [];
BetaVal.HbR = [];
BetaVal.HbT = [];
TVal.HbO = [];
TVal.HbR = [];
TVal.HbT = [];
PVal.HbO = [];
PVal.HbR = [];
PVal.HbT = [];

TVal.Contrast.HbO = [];
TVal.Contrast.HbR = [];
TVal.Contrast.HbT = [];
PVal.Contrast.HbO = [];
PVal.Contrast.HbR = [];
PVal.Contrast.HbT = [];


for hh=1:3 % 1 = HbO; 2 = HbR; 3 = HbT
    if hh==1 
        keyword_start = 'Model fit per channel for oxy-Hb (beta, t, p values)';
        keyword_finish = 'Model fit per channel for deoxy-Hb (beta, t, p values)';
    elseif hh==2
        keyword_start = 'Model fit per channel for deoxy-Hb (beta, t, p values)';
        keyword_finish = 'Model fit per channel for total-hb (beta, t, p values)';        
    else
        keyword_start = 'Model fit per channel for total-hb (beta, t, p values)';
        keyword_finish = 'GLM CONTRAST RESULTS';
    end
    
    % get  location of  coefficients of interest
    tmpStart = strfind(GLM_txt,keyword_start);
    indStart = find(~cellfun(@isempty,tmpStart)) + 1; 
    tmpFinish = strfind(GLM_txt,keyword_finish);
    indFinish = find(~cellfun(@isempty,tmpFinish)) -2; 

    if NrOfSDD>0
        % get row indices where short distance detectors indices are located & remove them
        indSDD =  strfind(GLM_txt(1:indFinish),'D8'); % in our case, we don't have more than 7 short distance detectors
        indSDD = [find(~cellfun(@isempty,indSDD)) find(~cellfun(@isempty,indSDD))+ (NrOfSDD-1)]; 
        indx_temp = indStart:indFinish;
        toRemove = [];
        for int=1:size(indSDD,1)
            toRemove = [toRemove; (indSDD(int,1):indSDD(int,2))'];        
        end
        indx = setdiff(indx_temp, toRemove); % remove SDD indices
        
    else
        indx = indStart:indFinish;
    end
      
   
    % initialize variables
    channelID = cell(numel(indx),1);
    temp_BetaVal = zeros(numel(indx),NrOfTasks);
    temp_TVal = zeros(numel(indx),NrOfTasks);
    temp_PVal = zeros(numel(indx),NrOfTasks);
    
    for cc=1:numel(indx)% for all normal distance channels in the setup
        temp= GLM_txt(indx(cc));
        
        % find white spaces in array and use them to find beta coefficients
        whiteSpaceInd = isspace(temp{1})';
        whiteSpaceInd = whiteSpaceInd(1:end-1)- whiteSpaceInd(2:end) ;
        startPeriod = find(whiteSpaceInd==1)+1;
        endPeriod = find(whiteSpaceInd==-1);
        matrix = [[1;startPeriod] endPeriod];
        
        % channelID is always the first column
        channelID{cc} = temp{1}(matrix(1,1):matrix(1,2)-1);
        matrix = matrix(2:end,:);
        
        % beta values are located every third value in the matrix
        indxB = 1:3:size(matrix,1);
        indxT = 2:3:size(matrix,1);
        indxP = 3:3:size(matrix,1);

        for int=1:NrOfTasks
            temp_BetaVal(cc,int) = str2double(temp{1}(matrix(indxB(int),1):matrix(indxB(int),2))); % save beta values
            temp_TVal(cc,int) = str2double(temp{1}(matrix(indxT(int),1):matrix(indxT(int),2))); % save beta values
            temp_PVal(cc,int) = str2double(temp{1}(matrix(indxP(int),1):matrix(indxP(int),2))); % save beta values
        end 
        
    end
    
    if hh==1
       BetaVal.HbO = temp_BetaVal;
       TVal.HbO = temp_TVal;
       PVal.HbO = temp_PVal;
    elseif hh==2
       BetaVal.HbR = temp_BetaVal;
       TVal.HbR = temp_TVal;
       PVal.HbR = temp_PVal; 
    else
       BetaVal.HbT = temp_BetaVal;
       TVal.HbT = temp_TVal;
       PVal.HbT = temp_PVal;  
    end
    
   %% Extract contrast-related information   

    if hh==1 % get oxy values
        keyword_start = 'Contrast results per channel for oxy-Hb (t, p values)';
        keyword_finish = 'Contrast results per channel for deoxy-Hb (t, p values)';
    elseif hh==2
        keyword_start = 'Contrast results per channel for deoxy-Hb (t, p values)';
        keyword_finish = 'Contrast results per channel for total-hb (t, p values)';
    else
        keyword_start = 'Contrast results per channel for total-hb (t, p values)';
        keyword_finish = '';
    end

    % get  where  coefficients of interest are shown
    tmpStart = strfind(GLM_txt,keyword_start);
    indStart = find(~cellfun(@isempty,tmpStart)) + 1; 
    if ~isempty(keyword_finish)
        tmpFinish = strfind(GLM_txt,keyword_finish);
        indFinish = find(~cellfun(@isempty,tmpFinish)) -2; 
    else
        indFinish = size(GLM_txt,1);
    end


    if NrOfSDD>0
        % get row indices where short distance detectors indices are shown & remove them
        indSDD =  strfind(GLM_txt(1:indFinish),['D' num2str(min(SDindx))]);
        indSDD = [find(~cellfun(@isempty,indSDD)) find(~cellfun(@isempty,indSDD))+ (NrOfSDD-1)]; 
        indx_temp = indStart:indFinish;
        toRemove = [];
        for int=1:size(indSDD,1)
            toRemove = [toRemove; (indSDD(int,1):indSDD(int,2))'];        
        end
        indx = setdiff(indx_temp, toRemove); % remove SDD indices
    else
        indx = indStart:indFinish;
    end

    % define #of contrasts
    keyword_start = 'GLM CONTRAST RESULTS';
    keyword_finish = 'Contrast results per channel for oxy-Hb (t, p values)';
    tmpStart = strfind(GLM_txt,keyword_start);
    indStart = find(~cellfun(@isempty,tmpStart)) + 1; 
    tmpFinish = strfind(GLM_txt,keyword_finish);
    indFinish = find(~cellfun(@isempty,tmpFinish)) -2;
    NrOfContrast = numel(indStart:indFinish);
    contrastNames = GLM_txt(indStart:indFinish);

    % define variables
    temp_TVal = zeros(numel(indx),NrOfContrast);
    temp_PVal = zeros(numel(indx),NrOfContrast);

    for cc=1:numel(indx)% for all normal distance channels in the setup
        temp= GLM_txt(indx(cc));

        % find white spaces in array and use them to find beta coefficients
        whiteSpaceInd = isspace(temp{1})';
        whiteSpaceInd = whiteSpaceInd(1:end-1)- whiteSpaceInd(2:end) ;
        startPeriod = find(whiteSpaceInd==1)+1;
        endPeriod = find(whiteSpaceInd==-1);
        matrix = [[1;startPeriod] endPeriod];

        % channelID is always the first column --> not needed
        matrix = matrix(2:end,:);

        indxT = 1:2:size(matrix,1);
        indxP = 2:2:size(matrix,1);

        for int=1:NrOfContrast
            temp_TVal(cc,int) = str2double(temp{1}(matrix(indxT(int),1):matrix(indxT(int),2))); % save beta values
            temp_PVal(cc,int) = str2double(temp{1}(matrix(indxP(int),1):matrix(indxP(int),2))); % save beta values
        end 

    end

    if hh==1
       TVal.Contrast.HbO = temp_TVal;
       PVal.Contrast.HbO = temp_PVal;
    elseif hh==2
       TVal.Contrast.HbR = temp_TVal;
       PVal.Contrast.HbR = temp_PVal; 
    else
       TVal.Contrast.HbT = temp_TVal;
       PVal.Contrast.HbT = temp_PVal;          
    end
    TVal.Contrast.Name = contrastNames;
    PVal.Contrast.Name = contrastNames;

    
end