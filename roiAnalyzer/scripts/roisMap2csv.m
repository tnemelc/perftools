% roisMap2csv.m
% brief:
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
% date: 17-Apr-2018


function [arg3, arg4] = roisMap2csv(arg1, arg2)
    rootPath = 'D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\clustering';
    resultsFolderPath = fullfile(rootPath, '0000_Results');
    isKS = {'apex', 'mid', 'base'};
    
    roiFeatKS = {'rois', 'roiSurface', 'peakVal', 'ttp', 'auc', 'maxSlope', 'maxSlopePos', ...
         'baseLineLen', 'roiCnr', 'roiBaseLineStd', 'voxelPeakVal', 'voxelCnr', ...
         'voxelAvgCnrOfRoi', 'voxelBaselineStd', 'voxelAvgBaselineStdOfRoi', ...
         'roi2vxlPeakValRelativeErr', 'roiAvgRoi2vxlPeakValRelativeErr', 'roi2vxlBaselineStdRatio',...
         'roi2vxlTicRelativeSse', 'roiAvgRoi2vxlTicRelativeSse'};
     
     if ( exist(resultsFolderPath, 'dir') )
         rmdir(resultsFolderPath, 's')
     end
     
    PatientList = dir(rootPath);
    curFeatTab = nan(400, length(isKS) *  length(PatientList), length(roiFeatKS));
    PatientList = PatientList(3:end);
    
    for k = 1 : length(PatientList)
        if strncmp(PatientList(k).name, '0000', 4)
            % folder starting by 0000 are not patients folder
            continue;
        end
        for m = 1 : length(roiFeatKS)
            curFeat = char(roiFeatKS(m));
            for n = 1 : length(isKS)
                isName = char(isKS(n));
                roisMap = loadmat(fullfile(rootPath, PatientList(k).name, 'autoRoiAnalysis', isName, 'rois'));
                roisUniqueTab = unique(roisMap);
                roisFirstItemTab = [];
                for p = 1 : length(roisUniqueTab)
                    roisFirstItemTab(p) = find(roisMap == roisUniqueTab(p), 1, 'first');
                end
                imSerieFeatTab = loadmat(fullfile(rootPath, PatientList(k).name, 'autoRoiAnalysis', isName, curFeat));
                
                curFeatTab(1 : length(roisFirstItemTab), (k - 1) * length(isKS) + n, m) = imSerieFeatTab(roisFirstItemTab);
            end%for m = 1 : length(isKS)
            
        end%for m = 1 : length(roiFeatKS)
    end%for k = 3 : length(PatientList)
    
    mkdir(resultsFolderPath)
    for k = 1 : length(roiFeatKS)
        curFeat = char(roiFeatKS(k));
        fid = fopen(fullfile(resultsFolderPath, [curFeat '.csv']), 'w');
        if fid > 1
            try
                for  p = 1 : size(curFeatTab, 1)
                    fprintf(fid, '%0.02f,', curFeatTab(p, :, k));
                    fprintf(fid, '\n');
                end
            catch e
                fclose(fid);
                rethrow(e);
            end
            fclose(fid);
        end
    end

end


