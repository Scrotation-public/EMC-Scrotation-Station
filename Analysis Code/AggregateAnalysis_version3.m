clear all;
close all;

ScalingAnalysis = false;

if ScalingAnalysis
    readXValues = ["linear", "log", "distance"];
else
    readXValues = [""];
end
global readX;

%% Enter In Information for making Folder
dName = FolderNameGenerator();
disp(dName);

%% Experiment Information
[protocolNames, colors, linestyle, axNames, refD] = experimentInformation();
S = {'o', 'd', 's', 'h', '^', '*'};
refD = str2num(refD{1});
axes = axNames;
%% Choose Large Meta Folder
myDir = uigetdir; %gets directory
listing = dir(myDir);
%listing = listing([1,2,4:end]);


for ii = 3:length(listing)
    subFolder(ii-2).subfolder = listing(ii).name;
    fileList(ii-2).files = dir(fullfile(myDir, listing(ii).name, '*.csv')); 
end

for i = 1:length(readXValues)
    readX = readXValues(i);
    switch readX
        case "linear"
            refDist = refD;
            axes{1} = axNames{1} + " (°)";
            dirName = "Linear analysis - " + dName;
        case "log"
            refDist = log(refD);
            axes{1} = "Log of " + axNames{1} + " (log °)";
            dirName = "Log analysis - " + dName;
        case "distance"
            refDist = 1.4 * tan(8 * pi/180) / tan(refD * pi/180);
            axes{1} = "Distance (m)";
            dirName = "Distance analysis - " + dName;
        otherwise
            refDist = refD;
            axes{1} = axNames{1};
            dirName = dName;
    end
    mkdir(dirName);

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
            angles = unique(dist);
            RT = data(:,3);
            idn = find(correct == 0);
            RT(idn) = 0;
            masterAngles = [masterAngles; angles];
            masterAngles = unique(masterAngles);
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
    
    
    %% Plotting
    plotSeparate = 'False';
    [outputParamStats, protocolOutput, h] = plotSubjectData_v3(fileList,listing,...
        angleRT_Mean, angleRT_StdErr, myDir, linestyle, protocolNames, S, axes, colors,...
        masterAngles, refDist, plotSeparate, dirName);
    %% Plotting Incorrect Percentages
    cd(dirName);
    mkdir("Accuracy Bar Graphs");
    cd("Accuracy Bar Graphs");
    for k = 1:length(fileList)
        mkdir(strcat(protocolNames{k}, 'Percentage Correct'));
        cd(strcat(protocolNames{k}, 'Percentage Correct'));
        folderPath = fullfile(listing(k+2).folder, listing(k+2).name);
        addpath(folderPath);
        for ii = 1:length(fileList(k).files)
            file = fileList(k).files(ii).name;
            fprintf(1, 'Now Reading %s\n' , fileList(k).files(ii).name);
            data = table2array(readtable(fileList(k).files(ii).name));
            dist = data(:,2);
            angles = unique(dist);
            bar(angles, 100*(1-[angleRT_IncorrectPerc(k).protocol(ii).subject.data]));
            for jj = 1:length([angleRT_IncorrectPerc(k).protocol(ii).subject])
                binomSTDE = 100*sqrt([angleRT_IncorrectPerc(k).protocol(ii).subject.data].*...
                    (1-[angleRT_IncorrectPerc(k).protocol(ii).subject.data])...
                    /length(angleRT_Raw(k).protocol(ii).subject(jj).data));
            end
            hold on;
            errorbar(angles, (100*(1-[angleRT_IncorrectPerc(k).protocol(ii).subject.data])),...
                [binomSTDE],'o', 'Color', 'r', 'MarkerFaceColor', 'r', 'MarkerSize', 0.1);
            ylim([30 100]);
            xlabel('Eccentricity (°)');
            ylabel('Percentage Incorrect');
            title(strcat('Subject', {' '}, string(ii), {' '}, 'Percentage Correct for',...
                {' '}, string(protocolNames{k})));
            saveas(gcf, strcat('Subject', '_', string(ii), 'PercCorrect.png'));
            hold off;
        end
        cd ..
    end
    cd ..

    %% Output to XLSX
    mkdir("Parameter Tables");
    cd("Parameter Tables");
    for ii = 1:length(outputParamStats)
        tableStats = struct2table(outputParamStats(ii));
        fileName = strcat('output-Parameters for' , {' '}, ...
            string(protocolNames{ii}), '.xlsx');
        fileName = regexprep(fileName, ' ', '_');
        writetable(tableStats, fileName, 'Sheet', 1);
    end
    cd ..
     %%  Slope vs Intercept
     
     close all;
     SlopeVals =[];
     InterceptVals =[];
     for ii = 1: length(fileList)
        
         
         Subject_slope = [outputParamStats(ii). slopePos; abs(outputParamStats(ii).slopeNeg)];
         Subject_intercept = [outputParamStats(ii). interceptPos; outputParamStats(ii).interceptNeg];
         Subject_slope_std = [outputParamStats(ii). slopePosErr; abs(outputParamStats(ii).slopeNegErr)];
         Subject_intercept_std = [outputParamStats(ii). interceptPosErr; outputParamStats(ii).interceptNegErr];
         
         scatter(Subject_intercept, Subject_slope, S{ii}, 'filled', ...
                'LineWidth', 1, 'MarkerFaceColor',colors{ii}, 'MarkerEdgeColor', colors{ii});  
            hold on;
            errorbar(Subject_intercept, Subject_slope,...
                Subject_slope_std, S{ii}, 'Vertical', 'Color', colors{ii},...
                'LineWidth', 1, 'CapSize', 0);
            hold on;
            errorbar(Subject_intercept, Subject_slope,...
                Subject_intercept_std, S{ii}, 'Horizontal', 'Color', colors{ii},...
                'LineWidth', 1, 'CapSize', 0);
            hold on;
            h(ii) = plot(2000, 'LineWidth', 1, 'MarkerFaceColor', colors{ii}, 'color', colors{ii}, ...
         'LineStyle', linestyle{ii}, 'MarkerSize', 5, 'DisplayName', protocolNames{ii},...
         'Marker', S{ii});
     hold on
     xlim([0 650]);
     ylim([-0.5 5]);
     
            SlopeVals = [SlopeVals; Subject_slope];
            InterceptVals = [InterceptVals; Subject_intercept];
     end
            OLSFit = polyfit(InterceptVals, SlopeVals, 1);
            Params = [OLSFit(1), OLSFit(2)];
            corCoef = corrcoef(Subject_intercept, Subject_slope);
            R = corCoef(1,2);
            h(length(fileList) +1) = plot(2000, 'LineWidth', 1, 'LineStyle', '-',...
                'color', 'k', 'DisplayName', strcat('R = ', num2str(R)));
            
            
            legend(h, 'Location', 'Northeastoutside', 'AutoUpdate', 'off');
            set(gcf, 'Position',  [20, 20, 1000, 800]);
            title( 'Slope vs Intercept');
            
      saveas(gcf, fullfile(pwd, strcat('Slope vs Intercept', '_',...
                     '.png')));
     %%
     %%ChiSquare Histograms
     
     close all;
     for ii = 1: length(fileList)
         figure(ii)
         
         allredchi = [outputParamStats(ii).redChi2Pos;outputParamStats(ii).redChi2Neg];
         Histogram = histfit(allredchi, 10, 'gamma');
         pd = gamfit(allredchi, 10);
         %mu = median(pd);
         xlabel('Reduced Chi Square');
         ylabel('');
         ylim([0 15]);
         xlim([0 14]);
         title(strcat(string(protocolNames{ii})));
         mkdir('Chi Square Histograms')
         saveas(gcf, fullfile(pwd,  'Chi Square Histograms' ,strcat( protocolNames{ii}, '.png')));
         
     end
    
    
    %% Hypothesis Testing/Error Analysis
    cd ..
    [incorrectHypArray] = hypothesisTesting_v3(fileList, listing,...
        angleRT_Raw, masterAngles);
    
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
            angles = unique(dist);
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
                angles = unique(dist);
                
                
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
            angles = unique(dist);
          
            masterAngles = [angles];
            masterAngles = unique(masterAngles);
            
       
    
    
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
            angles = unique(dist);
            
            masterAngles = [angles];
            masterAngles = unique(masterAngles);
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
            angles = unique(dist);
          
            masterAngles = [angles];
            masterAngles = unique(masterAngles);
           end
    
    
        protocolChiFitPos(k) = chiSquareFunction(masterAngles(masterAngles >= refDist)...
            ,protocolWeightedMean(k,find(masterAngles >= refDist))...
            ,protocolStdErr(k,find(masterAngles >= refDist)));
        protocolChiFitNeg(k) = chiSquareFunction(masterAngles(masterAngles <= refDist)...
            ,protocolWeightedMean(k,find(masterAngles <= refDist))...
            ,protocolStdErr(k,find(masterAngles <= refDist)));
    end
    
    %% Output Aggregate Parameters to XLSX
    cd(fullfile(dirName, "Parameter Tables"));
    for ii = 1:length(protocolNames)
        protocolChiFit(ii).slopePos = protocolChiFitPos(ii).slope;
        protocolChiFit(ii).slopePosErr = protocolChiFitPos(ii).slopeErr;
        protocolChiFit(ii).slopeNeg = protocolChiFitNeg(ii).slope;
        protocolChiFit(ii).slopeNegErr = protocolChiFitNeg(ii).slopeErr;
        protocolChiFit(ii).interceptPos = protocolChiFitPos(ii).intercept;
        protocolChiFit(ii).interceptPosErr = protocolChiFitPos(ii).interceptErr;
        protocolChiFit(ii).interceptNeg = protocolChiFitNeg(ii).intercept;
        protocolChiFit(ii).interceptNegErr = protocolChiFitNeg(ii).interceptErr;
        protocolChiFit(ii).chi2valPos = protocolChiFitPos(ii).chi2Val;
        protocolChiFit(ii).redChi2Pos = protocolChiFitPos(ii).redChiSquare;
        protocolChiFit(ii).chi2valNeg = protocolChiFitNeg(ii).chi2Val;
        protocolChiFit(ii).redChi2Neg = protocolChiFitNeg(ii).redChiSquare;
        protocolChiFit(ii).R_Pos = protocolChiFitPos(ii).R;
        protocolChiFit(ii).R_Neg = protocolChiFitNeg(ii).R;
        tableStats = struct2table(protocolChiFit(ii));
        fileName = strcat('Aggregate-Parameters-for',{' '}, string(protocolNames(ii)),...
            '.xlsx');
        fileName = regexprep(fileName, ' ', '_');
        writetable(tableStats, fileName, 'Sheet', 1);
    end
    cd ..
    cd ..
    
    %%  Protocol Plotting 
    close all;
    direc = fullfile(dirName, 'Stacked Plots', 'Protocol Plots');
    mkdir(direc);
    color = {[0.85098      0.32549     0.098039], [0.92941      0.69412      0.12549], [0.49412      0.18431      0.55686], [0.46667      0.67451      0.18824], [0.30196       0.7451      0.93333], [0.63529     0.078431      0.18431], [0.71765      0.27451            1], [0.65098      0.65098      0.65098], [0.66667      0.98039      0.43922], [0.078431       0.5098      0.10588], [0.90196      0.54118      0.61176], [0.062745     0.062745      0.52941], [0.61961      0.25882      0.35686]};
    SubjectNames = {'1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', ...
        '16', '17', '18', '19', '20'}
    plotProtocolData_v3(fileList,listing,...
        angleRT_Mean, angleRT_StdErr, myDir, linestyle, protocolNames, S, axes,...
        masterAngles, refDist, color, SubjectNames,  protocolWeightedMean,...
        protocolStdErr,protocolChiFitPos, protocolChiFitNeg, direc)
    
    %%  Protocol Plotting Normalized
    close all;
    direc = fullfile(dirName, 'Stacked Plots', 'Normalized Protocol Plots');
    mkdir(direc);
    plotProtocolData_v3(fileList,listing,...
        angleRT_Norm, angleRT_StdErr, myDir, linestyle, protocolNames, S, axes,...
        masterAngles, refDist, color, SubjectNames,  protocolWeightedMean,...
        protocolStdErr,protocolChiFitPos, protocolChiFitNeg, direc)
    
    %%  Aggregate Plotting
    figure();
    aggregatePlotting_v3(fileList, masterAngles, protocolWeightedMean, colors,...
        protocolStdErr,protocolChiFitPos, protocolChiFitNeg, linestyle,protocolNames, S,...
        axes, refDist, dirName);
end