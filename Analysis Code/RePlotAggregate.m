clear all;
close all;
%% Experiment Information
protocolNames = {'Faces Roll RT', 'Faces Yaw RT', 'Faces Pitch RT', ...
    'English Roll RT', 'Thai Roll RT', 'Chinese Roll RT'};

%colors = {'red', 'blue', 'green', 'magenta', 'cyan', 'black'};
colors = {[0.8 0 0.1], [0 0 0.85], [0 0.7 0], [0.7 0 0.8], [0 0.75 0.7], [0 0 0]};

linestyle = {'-', '-', '-', '-', '-', '-'};
refDist = 0;
S = {'o', 'd', 's', 'h', '^', '*'};
axes = {'Angle of Rotation (°)', 'Reaction Time (ms)'};

%% Plotting Protocol Comparison Plots
%{
protocolNames = {'Group A', 'Group B', 'Group C', 'Group D'};
colors = {[0.8 0.5 0], [0 0.75 0.1], [0 0 0.95], [0.6 0 0.75]};

protocolNum = 5;

marker = S{protocolNum};
titleText = protocolNames{protocolNum};
S = {marker, marker, marker, marker};
%}

%% Choosing Groups to plot
groups2Graph = [1];

%make lighter tint
for i = 1:length(colors)
    color = colors{i};
    dif = 0.4 * (1 - color);
    colors{i} = color + dif; end

protocolNames = protocolNames(groups2Graph);
colors = colors(groups2Graph);
S = S(groups2Graph);
linestyle = linestyle(groups2Graph);
titleText = "Group D Faces";

%% Choose Large Meta Folder
myDir = uigetdir; %gets directory
listing = dir(myDir);
listing = listing([1,2,groups2Graph + 2]);
for ii = 3:length(listing)
    subFolder(ii-2).subfolder = listing(ii).name;
    fileList(ii-2).files = dir(fullfile(myDir, listing(ii).name, '*.csv')); 
end

%% Sort Through Data
masterAngles = [];
for k = 1:length(fileList)
    data=[];
    RT=[];
    
    folderPath = fullfile(listing(k+2).folder, listing(k+2).name);
    addpath(folderPath);
    for ii = 1:length(fileList(k).files)
        file = fileList(k).files(ii).name;
        fprintf(1, 'Now Reading %s\n' , fileList(k).files(ii).name);
        data = table2array(readtable(fileList(k).files(ii).name));
        dist = data(:,2);
        correct = data(:,1);
        angles = unique(dist(~isnan(dist)));
        RT = data(:,3);
        idn = find(correct == 0);
        RT(idn) = 0;
        masterAngles = [masterAngles; angles];
        masterAngles = unique(masterAngles(~(masterAngles)));
        for jj = 1:length(angles)
            idx = find(dist == angles(jj));
            RT_IDX = RT(idx);
            RT_IDX = RT_IDX(RT_IDX~=0);
            correct_IDX = correct(idx);
            angleRT_Raw(k).protocol(ii).subject(jj).data = RT(idx);
            angleRT_Incorrect(k).protocol(ii).subject(jj).data = sum(correct_IDX(:) == 0);
            angleRT_IncorrectPerc(k).protocol(ii).subject(jj).data = sum(correct_IDX(:) == 0)/...
                length(RT_IDX);
            RT_IDX = RT_IDX(RT_IDX~=0);
            [RT_IDX_RMO, TF] = rmoutliers(RT_IDX, 'quartiles');
            angleRT_RMO(k).protocol(ii).subject(jj).data = RT_IDX_RMO;
            angleRT_outlier(k).protocol(ii).subject(jj).data = sum(TF);
            angleRT_Mean(k).protocol(ii).subject(jj).data = mean(RT_IDX_RMO);
            angleRT_StdErr(k).protocol(ii).subject(jj).data = std(RT_IDX_RMO)/...
                sqrt(length(RT_IDX_RMO));
        end
    end        
end

%% Normalize Data
for ii = 1: length(fileList)
    data=[];
    RT=[];
    
    protocolRT_allSub(ii).data =[];
    protocolStd_allSub(ii).data = [];
    for jj = 1:length(fileList(ii).files)
        protocolRT_allSub(ii).data = [protocolRT_allSub(ii).data, angleRT_Mean(ii).protocol(jj).subject.data];
        protocolStd_allSub(ii).data = [protocolStd_allSub(ii).data, angleRT_StdErr(ii).protocol(jj).subject.data];
        
    end 

    ProtocolRT_Mean(ii).data = sum(protocolRT_allSub(ii).data./protocolStd_allSub(ii).data)/sum(1./protocolStd_allSub(ii).data);  

    
    for jj = 1:length(fileList(ii).files)
        data = table2array(readtable(fileList(ii).files(jj).name));
        dist = data(:,2);
        angles = unique(dist(~isnan(dist)));
        protocolRT_indvSub(ii).subject(jj).data = [];
        protocolStd_indvSub(ii).subject(jj).data= [];
        for k = 1:length(angles)
            protocolRT_indvSub(ii).subject(jj).data = [protocolRT_indvSub(ii).subject(jj).data, angleRT_Mean(ii).protocol(jj).subject(k).data];
            protocolStd_indvSub(ii).subject(jj).data = [protocolStd_indvSub(ii).subject(jj).data, angleRT_StdErr(ii).protocol(jj).subject(k).data];
        end
    end 

        
        for jj = 1:length(fileList(ii).files)
            ProtocolRTind_Mean(ii).subject(jj).data = sum(protocolRT_indvSub(ii).subject(jj).data./protocolStd_indvSub(ii).subject(jj).data)/sum(1./protocolStd_indvSub(ii).subject(jj).data);  
            data = table2array(readtable(fileList(ii).files(jj).name));
            dist = data(:,2);
            angles = unique(dist(~isnan(dist)));
            
            
        for k = 1:length(angles)
            angleRT_Norm(ii).protocol(jj).subject(k).data = angleRT_Mean(ii).protocol(jj).subject(k).data - ProtocolRTind_Mean(ii).subject(jj).data + ProtocolRT_Mean(ii).data;
        end
    end
end


%% Aggregate Analysis
masterAngles = [];
handles = [];
for k = 1:length(fileList)
    data=[];
    RT=[];
   folderPath = fullfile(listing(k+2).folder, listing(k+2).name);
   addpath(folderPath);
   clear angles;
   clear masterAngles;
   for ii = 1:length(fileList(k).files)
       fprintf(1, 'Now Reading %s\n' , fileList(k).files(ii).name);
        data = table2array(readtable(fileList(k).files(ii).name));
        dist = data(:,2);
        angles = unique(dist(~isnan(dist)));
      
        masterAngles = [angles];
        masterAngles = unique(masterAngles(~isnan(masterAngles)));
        
   


        for jj = 1:length(angles)
            idx = find(masterAngles == angles(jj));
            aggregateMeans(ii, idx, k) = angleRT_Norm(k).protocol(ii).subject(jj).data;
            aggregateSTDE(ii,idx,k) = angleRT_StdErr(k).protocol(ii).subject(jj).data;
        end
   end
end 
% aggregateMeans(find(incorrectHypArray >= 0.05 & incorrectHypArray <= 1)) = NaN;
% aggregateSTDE(find(incorrectHypArray >= 0.05 & incorrectHypArray <= 1)) = NaN;
aggregateMeans(aggregateMeans == 0) = NaN;
aggregateSTDE(aggregateSTDE == 0) = NaN;

for k = 1:length(fileList)
    data=[];
    RT=[];
       for ii = 1:length(fileList(k).files)
       fprintf(1, 'Now Reading %s\n' , fileList(k).files(ii).name);
        data = table2array(readtable(fileList(k).files(ii).name));
        dist = data(:,2);
        angles = unique(dist(~isnan(dist)));
        
        masterAngles = [angles];
        masterAngles = unique(masterAngles(~isnan(masterAngles)));
       end
    for jj = 1:length(masterAngles)
        protocolWeightedMean(k, jj) = sum(aggregateMeans(:,jj,k)./aggregateSTDE(:,jj,k), ...
            'omitnan')/sum(1./aggregateSTDE(:,jj,k) , 'omitnan');
        protocolStdErr(k,jj) = std(aggregateMeans(:,jj,k)/...
            sqrt(length(aggregateMeans(:,jj,k))),...
            'omitnan').* (length(angles)./(length(angles)-1));
    end
end
for k = 1:length(fileList)
    data=[];
    RT=[];
       for ii = 1:length(fileList(k).files)
       fprintf(1, 'Now Reading %s\n' , fileList(k).files(ii).name);
        data = table2array(readtable(fileList(k).files(ii).name));
        dist = data(:,2);
        angles = unique(dist(~isnan(dist)));
      
        masterAngles = [angles];
        masterAngles = unique(masterAngles(~isnan(masterAngles)));
       end


    protocolChiFitPos(k) = chiSquareFunction(masterAngles(masterAngles >= refDist)...
        ,protocolWeightedMean(k,find(masterAngles >= refDist))...
        ,protocolStdErr(k,find(masterAngles >= refDist)));
    protocolChiFitNeg(k) = chiSquareFunction(masterAngles(masterAngles <= refDist)...
        ,protocolWeightedMean(k,find(masterAngles <= refDist))...
        ,protocolStdErr(k,find(masterAngles <= refDist)));
end

%%  Aggregate Plotting
mkdir('combined_plots');
aggregatePlotting_v3(fileList, masterAngles, protocolWeightedMean, colors,...
    protocolStdErr,protocolChiFitPos, protocolChiFitNeg, linestyle,protocolNames, S,...
    axes, refDist);

if ~exist('titleText', 'var'); titleText = ''; end
title(titleText);
fig = gcf;
fig.Position = [500 -250 850 1000];
%fig.Position = [500 -250 650 1000];
ylim([400 800]);


%% Swap axes
%{
fig = gcf;
fig.Position = [500 -250 1000 400];
view([90 -90]);
%}
