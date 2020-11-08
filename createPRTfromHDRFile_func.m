
function []=createPRTfromHDRFile_func(SamplingRate,prt_info,filePath,fileName,triggerInfo,last_rest)
% this function creates 2 prt files from the hdr file: one in seconds
% (volumes) and one in frames

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% input

% SamplingRate -> in Hz
% prt_info -> Nx3 matrix extracted from hdr file that defines the trigger
%             information
% filePath -> path where hdr file is located
% fileName -> hdr file name
% restTrig -> flag that defines whether the hdr file includes rest triggers
%             or not (if it does,the code for rest should be always 1)
% last_rest -> if restTrig ==1 :defines the duration of the last rest period (in seconds).
%              if restTrig ==0 :define the duration of the run (in seconds)

% output
% 2 prt files in the same directory as the hdr file

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Dependencies:
% this function uses NeuroElf functions, version: v09d --> http://neuroelf.net/

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% author: AB, Maastricht University
% last edited: 25.03.19
%%

% last_rest: duration of last rest condition in seconds
seconds = prt_info(:,1);
triggers = prt_info(:,2);
frames = prt_info(:,3);


% saving name for prt file
tmp_prtName = fileName(1:end-4);
savingPath = filePath;
prt_SaveAs= {fullfile(savingPath,[tmp_prtName '.prt']),fullfile(savingPath,[tmp_prtName '_frames.prt'])};

% define parameters
CondNames= {'Rest','Task1','Task2','Task3','Task4','Task5','Task6','Task7','Task8','Task9','Task10'};
NrCond = length(unique(triggers));
CondColors =  [0.9 0.9 0.9;
               0.8 0 0; % R
			   0 0.8 0; % G
			   0 0 0.8; % B
			   0.8 0.8 0;
			   0.8 0 0.8;
			   0 0.8 0.8;
               0.6 0.6 0.8;
               0 0 0.5;
               0 0.5 0;
               0.8 0.5 0.6];

if triggerInfo.restTrigger ==0 % hdr file does not include rest trigger
    NrCond = length(intersect(unique(triggers),triggerInfo.taskTrigger));   
    CondNames = CondNames(2:end);
    CondColors = CondColors(2:end,:);    
end
CondColors = round(repmat(255,[size(CondColors,1),3]).*CondColors);

% template prt file
prt_file = xff('new:prt');
prt_copy = prt_file.CopyObject;
prt_copy.Experiment = 'test_experiment';

% create 2 kinds of prt files: 1 in seconds (volumes), 1 in Frames
for iter=1:2
    if iter==1
        disp('iter: prt in seconds' )
        arr_seconds= [seconds seconds];
        
        if triggerInfo.restTrigger==0
            tempArr = [];
            for int=1:numel(triggerInfo.taskTrigger)
               tempArr = [tempArr; find(triggers(:)==triggerInfo.taskTrigger(int))]; 
            end
            indx = setxor(1:size(triggers,1),unique(tempArr));

            window_trial = zeros(length(seconds)-numel(indx),2);
            for int=1:length(arr_seconds)-numel(indx)
               window_trial(int,:) = [arr_seconds(int,1) arr_seconds(int+1,2)] ;
            end 
            triggInd = setxor(1:size(triggers,1),indx);
            tmp_protocol = [window_trial triggers(triggInd)];
        else
            
            window_trial = zeros(length(seconds)-1,2);
            for int=1:length(arr_seconds)-1
               window_trial(int,:) = [arr_seconds(int,1) arr_seconds(int+1,2)] ;
            end 
            window_trial2 = [window_trial; arr_seconds(end,1) arr_seconds(end,1)+last_rest];
            tmp_protocol = [window_trial2 triggers];
        end        

        prt_copy.ResolutionOfTime = 'Seconds';
    elseif iter==2
        disp('iter: prt in frames' )
        all_frames = [frames frames];
              
        if triggerInfo.restTrigger==0
            tempArr = [];
            for int=1:numel(triggerInfo.taskTrigger)
               tempArr = [tempArr; find(triggers(:)==triggerInfo.taskTrigger(int))]; 
            end
            indx = setxor(1:size(triggers,1),unique(tempArr));
            
            window_trial = zeros(length(frames)-numel(indx),2);
            for int=1:length(frames)-numel(indx)
               window_trial(int,:) = [all_frames(int,1) all_frames(int+1,2)] ;
            end
            triggInd = setxor(1:size(triggers,1),indx);
            tmp_protocol = [window_trial triggers(triggInd)];
        else
            window_trial = zeros(length(frames)-1,2);
            for int=1:length(frames)-1
               window_trial(int,:) = [all_frames(int,1) all_frames(int+1,2)] ;
            end
           
            window_trial2 = [window_trial; frames(end,1) frames(end,1)+ceil(last_rest*SamplingRate)];
            tmp_protocol = [window_trial2 triggers];
        end
        
        prt_copy.ResolutionOfTime = 'Frames';
    end
    
    CondOnOffsets = cell(NrCond,1);
    CondTrigger = unique(triggers);
    NrOfTrials = zeros(NrCond,1);
    for int=1:NrCond
       CondOnOffsets{int} = tmp_protocol(tmp_protocol(:,3)==CondTrigger(int),1:2);
       NrOfTrials(int) = size(CondOnOffsets{int},1);
    end
    prt_copy.NrOfConditions = NrCond;
    for int=1:NrCond
        prt_copy.Cond(int).ConditionName = {CondNames{int}};
        prt_copy.Cond(int).NrOfOnOffsets = NrOfTrials(int);
        prt_copy.Cond(int).OnOffsets = CondOnOffsets{int};
        prt_copy.Cond(int).Color = CondColors(int,:);
        prt_copy.Cond(int).Weights = zeros(length(CondOnOffsets{int}),0);
    end
    % Save prt files

    prt_copy.SaveAs(prt_SaveAs{iter}) 
end

