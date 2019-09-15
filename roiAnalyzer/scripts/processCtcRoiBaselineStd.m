% deconvPatientsRoiList.m
% brief: run deconvolution on patients' ROI average time intensity curves
% only lelsion roi are processed
%
%
% references:
%
%
% input:
% arg1: ...
% arg2: ...
% output:
%
% arg3: ...
% arg4: ...
%
%
% keywords:
% author: C.Daviller
% date: 21-Nov-2018


function [arg3, arg4] = processCtcRoiBaselineStd(arg1, arg2)
    lgr = logger.getInstance();
    rootPath = 'D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\clustering\';
    lesionPatientSet = {
        '0001_ARGE', '0002_FACL', '0003_CHAL', ...
        '0004_JUMI', '0005_COJE', '0006_THRO', ...
        '0007_OUGW', '0009_DEAL', '0012_RIAL', ...
        '0015_ROJE', '0018_SALI', '0019_GRIR', ...
        '0021_CUCH', '0022_HODO', '0024_IBOU', ...
        '0027_CRCH', '0029_HURO', '0030_MARE', ...
        '0039_MOBE', '0040_SEJO', '0041_LUEL', ...
        '0042_BELA', '0048_BUJA', '0049_POAI', ...
        '0050_BRFR', '0052_CLYV', '1001_BODA', ...
        '1002_NEMO'};
%     lesionPatientSet = {'0003_CHAL', '0002_FACL'};
    
    mode = '[Gd]';
%     mode = 'Signal';
    
    patientSet = lesionPatientSet;

    
    %table init
    avgCtcBaseLineTabStd.apex = [];
    avgCtcBaseLineTabStd.mid = [];
    avgCtcBaseLineTabStd.base = [];
    
    roiCtcBaselineTabStd.apex = [];
    roiCtcBaselineTabStd.mid = [];
    roiCtcBaselineTabStd.base = [];
    
    for k = 1 : length(patientSet)
        lgr.info(sprintf('patient: %s', patientSet{k}));

        curPatient =  char(patientSet(k));
        patientPath = fullfile(rootPath, curPatient);

        %
        slcKS = {'base', 'mid', 'apex'};

        for n = 1 : length(slcKS)
            lgr.info(sprintf('%s', slcKS{n}));

            roiToolOpt.dataPath = fullfile(rootPath, curPatient);
            
            switch mode
                case 'Signal'
                roiTool = kMeanStrgRoiAnalyzerTool;
                case '[Gd]'
                roiTool = kMeanStrgRoiAnalyzerToolCtc;
            end
            
            roiTool = roiTool.prepare(roiToolOpt);
            roiTool = roiTool.run(roiToolOpt);
            
            %extract roi mask 
            roiMask = roiTool.getRoisMask(slcKS{n});
            %eliminate roi that are not lesion
            nbRois = max(roiMask(:));
            for m = 1 : nbRois
               if ~strncmp('lesion', roiTool.getRoiLabel(slcKS{n}, m), length('lesion'))
                   roiMask(roiMask == m) = 0;
               end
            end
            %gather time intensity curve of lesion region
            
            for m = 1 : nbRois
                avg_ctc = [];
                ctc_tab = [];
                if strncmp('lesion', roiTool.getRoiLabel(slcKS{n}, m), length('lesion'))
                    %get roi average concentration time curve
                    avg_ctc = (roiTool.getRoiAvgTic(slcKS{n}, m))';
                    [H, W]= size(roiMask);
                    pos = find(roiMask == m);
                    [X, Y] = ind2sub([H, W], pos);
                    tmpMask = zeros(H, W);
                    tmpMask (pos) = 1;
                    tmpCtc = roiTool.getTimCurvesFromMask(slcKS{n}, tmpMask)';
                    for p = 1 : length(X)
%                         tmp(X(p), Y(p)) = m;
                        ctc_tab(:, p) = roiTool.getVoxelTic(slcKS{n}, X(p), Y(p));
                    end
                end
                if tmpCtc ~= ctc_tab
                    lgr.err('data coherence conflict');
                end
                %get aif foot and use it as common baseline
                aifFootPos = roiTool.getAifFeature('footPos');
                
                avg = mean(mean(ctc_tab(3 : aifFootPos, :), 2));
                
                ctc_tab = ctc_tab - avg;
                
                h = figure; 
                plot(ctc_tab);
                hold on; plot(mean(ctc_tab, 2), 'linewidth', 3); grid;
                %calculate baseline std
                patientList.(curPatient(6 : end)).(slcKS{n}).(sprintf('roi%d', m)).roiAvgCtcBaseline = std(mean(ctc_tab(3 : aifFootPos, :), 2));
                patientList.(curPatient(6 : end)).(slcKS{n}).(sprintf('roi%d', m)).roiCtcBaseline = mean(std(ctc_tab(3 : aifFootPos, :)));
                close(h);
                
                switch mode
                    case 'Signal'
                        avgCtcBaseLineTabStd.(slcKS{n}) = [avgCtcBaseLineTabStd.(slcKS{n}) std(mean(ctc_tab(3 : aifFootPos, :), 2))];
                        roiCtcBaselineTabStd.(slcKS{n}) = [roiCtcBaselineTabStd.(slcKS{n}) mean(std(ctc_tab(3 : aifFootPos, :)))];
                    case '[Gd]'
                        %multiply with 1e6 factor to keep precision
                        avgCtcBaseLineTabStd.(slcKS{n}) = [avgCtcBaseLineTabStd.(slcKS{n}) std(mean(ctc_tab(3 : aifFootPos, :), 2)) * 1e6];
                        roiCtcBaselineTabStd.(slcKS{n}) = [roiCtcBaselineTabStd.(slcKS{n}) mean(std(ctc_tab(3 : aifFootPos, :))) * 1e6];
                end%switch
            end%for m = 1 : nbRois
        end%for n = 1 : length(slcKS)
    end%for k = 1 : length(patientSet)

    %create xml file
    root.patientList = patientList;
    struct2xml(root, fullfile(rootPath, '0000_Results', 'roibaselineStd.xml'));
    %create csv file
    
    fid = fopen(fullfile(rootPath, '0000_Results', 'roibaselineStd.csv'), 'w');
    avgCtcBLStdStr = 'avg ctc baseline std';
    roiCtcBLStdStr = 'roi ctc baseline std';
    
    try
        %write roi avg ctc baseline std
        for n = 1 : length(slcKS)
            
            avgCtcBLStdStr = sprintf('%s\n%s', avgCtcBLStdStr, slcKS{n});
            avgCtcBaseLineTab = avgCtcBaseLineTabStd.(slcKS{n});
            for k = 1 : length(avgCtcBaseLineTab)
                avgCtcBLStdStr = sprintf('%s, %.02f', avgCtcBLStdStr, avgCtcBaseLineTab(k));
            end
        end
        
        for n = 1 : length(slcKS)
            roiCtcBLStdStr = sprintf('%s\n%s', roiCtcBLStdStr, slcKS{n});
            roiCtcBaselineTab = roiCtcBaselineTabStd.(slcKS{n});
            for k = 1 : length(roiCtcBaselineTab)
                roiCtcBLStdStr = sprintf('%s, %f', roiCtcBLStdStr, roiCtcBaselineTab(k));
            end
        end
        
        fprintf(fid, '%s\n\n%s', avgCtcBLStdStr, roiCtcBLStdStr);
        
    catch
        lgr.err('pb occured during file write')
    end
    fclose(fid);
    
    system(sprintf('D:\\Programmes\\Notepad++\\notepad++.exe %s &', fullfile(rootPath, '0000_Results' , 'roibaselineStd.xml')));
    system(sprintf('start "" "C:\\Program Files (x86)\\Microsoft Office\\Office14\\EXCEL.EXE" %s', fullfile(rootPath, '0000_Results' , 'roibaselineStd.csv')));
end