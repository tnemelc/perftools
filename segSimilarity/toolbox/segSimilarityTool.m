classdef segSimilarityTool < cPerfImSerieTool
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        groundTruthMaskMap;
        normalMaskMap;
        kMeanMaskMap;
        strgMaskMap;
        %Dice index
        kMeanDiceCoeffMap;
        strgDiceCoeffMap;
        %intersection score
        intersectionScoreMap;
        kMeanHddMap;%kmean hausdorf distance
        strgHddMap;%kmean hausdorf distance
        %inclusien index
        kMeanInclusionMap;
        strgInclusionMap;
        %Jaccard  index
        kMeanJaccardIndexMap;
        strgJaccardIndexMap;
        %gravity center distance
        kmeanGCenterDistMap;
        strgGCenterDistMap;
        
        kMeanIntersectionMap;
        strgIntersectionMap;
        
        ahaSegmentsMaskMap;
        lesionAhaSegmentsMaskMap;
        normalAhaSegmentsMaskMap;
        segType;
    end
    
    methods (Access = public)
        %%
        function obj = run(obj, ~)
            obj = obj.run@cPerfImSerieTool();
            obj = obj.loadMyoMask();
            obj = obj.loadSegmentationMasks();
            obj = obj.processLesionAhaSegmentMasks();
            obj = obj.processMasksSimilarity();
            obj = obj.processInclusionCriterion();
        end
        %%
        function mask = getGndTruthMask(obj, isName)
            mask = obj.groundTruthMaskMap(isName);
        end
        %%
        function mask = getSegmentationMask(obj, isName, maskType)
            switch maskType
                case 'kMean'
                    mask = obj.kMeanMaskMap(isName);
                case 'strg'
                    mask = obj.strgMaskMap(isName);
                case 'aha'
                    mask = obj.ahaSegmentsMaskMap(isName);
                case 'ahaLesion'
                    mask = obj.lesionAhaSegmentsMaskMap(isName);
                case 'ahaNormal'
                    mask = obj.normalAhaSegmentsMaskMap(isName);
                case 'manualNormal'
                    mask = obj.normalMaskMap(isName);
            end
        end
        %%
        function simCoeff = getDiceCoeff(obj, isName, maskType)
            switch maskType
                case 'kMean'
                    simCoeff = obj.kMeanDiceCoeffMap(isName);
                case 'strg'
                    simCoeff = obj.strgDiceCoeffMap(isName);
            end
        end
        %%
        function simCoeff = getHaussdorfDist(obj, isName, maskType)
            switch maskType
                case 'kMean'
                    simCoeff = obj.kMeanHddMap(isName);
                case 'strg'
                    simCoeff = obj.strgHddMap(isName);
            end
        end
        %%
        function inclusionCoeff = getInclusionCoeff(obj, isName, maskType)
            switch maskType
                case 'kMean'
                    inclusionCoeff = obj.kMeanInclusionMap(isName);
                case 'strg'
                    inclusionCoeff = obj.strgInclusionMap(isName);
            end
        end
        %%
        function intersectionCoeff = getIntersectionCoeff(obj, isName, maskType)
            switch maskType
                case 'kMean'
                    intersectionCoeff = obj.kMeanIntersectionMap(isName);
                case 'strg'
                    intersectionCoeff = obj.strgIntersectionMap(isName);
            end
        end
        %% 
        function jaccardCoeff = getJaccardCoeff(obj, isName, maskType)
            switch maskType
                case 'kMean'
                    jaccardCoeff = obj.kMeanJaccardIndexMap(isName);
                case 'strg'
                    jaccardCoeff = obj.strgJaccardIndexMap(isName);
            end
        end
        
        function centroidDistVect = getCentroid(obj, isName, maskType)
            switch maskType
                case 'kMean'
                    centroidDistVect = obj.kmeanGCenterDistMap(isName);
                case 'strg'
                    centroidDistVect = obj.strgGCenterDistMap(isName);
            end
        end
        
    end%methods (Access = public)
    
    methods (Access = protected)
        %%
        function obj = loadSegmentationMasks(obj)
            
             for k = 1 : length(obj.isKS)
                 isName = obj.isKS{k};
                 manualMask = loadmat(fullfile(obj.dataPath, 'segmentation', 'ManualMultiRoiMapDisplay', ['labelsMask_' isName '.mat']));
                 roiInfoStruct = xml2struct(fullfile(obj.dataPath, 'segmentation', 'ManualMultiRoiMapDisplay', ['roiInfo_' isName '.xml']));
                 gndTrthMask = obj.extractLesionLabels(roiInfoStruct, manualMask);
                 normalMask = obj.extractNormalLabels(roiInfoStruct, manualMask);
                 
                 ahaMask = loadmat(fullfile(obj.dataPath, 'segmentation', 'AHA_Segments', isName, 'labeledImg.mat'));

                 kMeanSegMask = loadmat(fullfile(obj.dataPath, 'strg', isName, 'kMeanMask.mat'));
                 strgSegMask  = loadmat(fullfile(obj.dataPath, 'strg', isName, 'strgMask.mat'));
                 
                 obj.groundTruthMaskMap = mapInsert(obj.groundTruthMaskMap, isName, gndTrthMask);
                 obj.kMeanMaskMap = mapInsert(obj.kMeanMaskMap, isName, kMeanSegMask);
                 obj.strgMaskMap =  mapInsert(obj.strgMaskMap, isName, strgSegMask);
                 obj.ahaSegmentsMaskMap = mapInsert(obj.ahaSegmentsMaskMap, isName, ahaMask);
                 obj.normalMaskMap = mapInsert(obj.normalMaskMap, isName, normalMask);
             end
        end
        %%
        function lesionsMask = extractLesionLabels(obj, infoStruct, mask)
            roiInfoCells = infoStruct.roisInfo;
            lesionsMask = zeros(size(mask));
            for m = 1 : length(roiInfoCells.roi)
                if iscell(roiInfoCells.roi)
                    curRoiInfo = roiInfoCells.roi{m};
                else
                    curRoiInfo = roiInfoCells.roi;
                end
                if strncmp(curRoiInfo.name.Text, 'lesion', length('lesion'))
                    lesionId = str2double(curRoiInfo.id.Text);
                    lesionsMask(mask == lesionId) = 1;
                end
            end
        end
        
        %%
        function normalMask = extractNormalLabels(obj, infoStruct, mask)
            roiInfoCells = infoStruct.roisInfo;
            normalMask = zeros(size(mask));
            for m = 1 : length(roiInfoCells.roi)
                if iscell(roiInfoCells.roi)
                    curRoiInfo = roiInfoCells.roi{m};
                else
                    curRoiInfo = roiInfoCells.roi;
                end
                if strncmp(curRoiInfo.name.Text, 'normal', length('normal'))
                    lesionId = str2double(curRoiInfo.id.Text);
                    normalMask(mask == lesionId) = 1;
                end
            end
        end
        %%
        function obj = processMasksSimilarity(obj)
            for k = 1 : length(obj.isKS)
                 isName = obj.isKS{k};
                 
                 kmeanSimCoeff = dice(obj.groundTruthMaskMap(isName), obj.kMeanMaskMap(isName));
                 strgSimCoeff = dice(obj.groundTruthMaskMap(isName), obj.strgMaskMap(isName));
                 
                 kmeanHdd = HausdorffDist(obj.groundTruthMaskMap(isName), obj.kMeanMaskMap(isName));
                 strgHdd = HausdorffDist(obj.groundTruthMaskMap(isName), obj.strgMaskMap(isName));
                 
                 kmeanIntersectionCoeff = nnz(obj.groundTruthMaskMap(isName) & obj.kMeanMaskMap(isName));
                 strgIntersectionCoeff = nnz(obj.groundTruthMaskMap(isName) & obj.strgMaskMap(isName));
                 
                 kMeanCentoidDistVect = obj.processCentroidDistance(obj.groundTruthMaskMap(isName), obj.kMeanMaskMap(isName));
                 strgCentoidDistVect = obj.processCentroidDistance(obj.groundTruthMaskMap(isName), obj.strgMaskMap(isName));
                 
                 kMeanJaccardCoeff = jaccard(obj.groundTruthMaskMap(isName), obj.kMeanMaskMap(isName));
                 strgJaccardCoeff = jaccard(obj.groundTruthMaskMap(isName), obj.strgMaskMap(isName));
                 
                 % Dice
                 obj.kMeanDiceCoeffMap = mapInsert(obj.kMeanDiceCoeffMap, isName, kmeanSimCoeff);
                 obj.strgDiceCoeffMap = mapInsert(obj.strgDiceCoeffMap, isName, strgSimCoeff);
                 
                 % Haussdorf distance
                 obj.kMeanHddMap = mapInsert(obj.kMeanHddMap, isName, kmeanHdd);
                 obj.strgHddMap = mapInsert(obj.strgHddMap, isName, strgHdd);
                 
                 % intersection 
                 obj.kMeanIntersectionMap = mapInsert(obj.kMeanIntersectionMap, isName, kmeanIntersectionCoeff);
                 obj.strgIntersectionMap = mapInsert(obj.strgIntersectionMap, isName, strgIntersectionCoeff);
                 
                 %blobs' centroids distances
                 obj.kmeanGCenterDistMap = mapInsert(obj.kmeanGCenterDistMap, isName, kMeanCentoidDistVect);
                 obj.strgGCenterDistMap = mapInsert(obj.strgGCenterDistMap, isName, strgCentoidDistVect);
                                                        
                % Jaccard
                obj.kMeanJaccardIndexMap = mapInsert(obj.kMeanJaccardIndexMap , isName, kMeanJaccardCoeff);
                obj.strgJaccardIndexMap = mapInsert(obj.strgJaccardIndexMap, isName, strgJaccardCoeff);                    
            end
        end
        %% 
        function distTab = processCentroidDistance(obj, gndTruth, mask)
            %get each blobs centroids and area.
            statGdTh = regionprops(bwlabel(gndTruth),'centroid', 'Area');
            statMask = regionprops(bwlabel(mask),'centroid', 'Area');
            %sort gnd truth blobs by size;
            [a idx] = sort([statGdTh.Area], 'descend');
            
            %for each blobs in gnd truth search the closest one in mask and 
            % and keep the closest one
            distTab = ones(1, length(idx)) * inf;
            for k = 1 : length(idx)
                for m = 1 : length(statMask)
                    tmpDist = pdist([statGdTh(idx(k)).Centroid; statMask(m).Centroid], 'euclidean');
                    if tmpDist < distTab(k)
                        distTab(k) = tmpDist;
                    end
                end
            end
        end
        %%
        function obj = processInclusionCriterion(obj)
            for k = 1 : length(obj.isKS)
                 isName = obj.isKS{k};
                 
                 gTruth = obj.groundTruthMaskMap(isName);
                 gTruth(gTruth > 0) = 1;
                 kMean = obj.kMeanMaskMap(isName);
                 kMean(kMean > 0) = 1;
                 strg = obj.strgMaskMap(isName);
                 strg(strg > 0) = 1;
%                  if max(max(kMean - strg)) == 0
%                      obj.lgr.warn(sprintf('%s masks are equals', isName));
%                  end
                 %process the relative complement of ground truth in lesion detection 
                 % kMean \ gndTruth
                 % strg \  gndTruth
                 KMeanMinusGTruth = kMean;
                 KMeanMinusGTruth(gTruth > 0) = 0;
                 
                 strgMinusGTruth = strg;
                 strgMinusGTruth(gTruth > 0) = 0;
                 
%                  %process intersection
%                  kMeanInterGTruth = kMean;
%                  kMeanInterGTruth(gTruth == 0) = 0;
                 
%                  strgInterGTruth = strg;
%                  strgInterGTruth(gTruth == 0) = 0;
               
                 % process inclusion criterion as phi = 1 -
                 % kMeanMinusGTruth / kMean
                 kMeanInclusion = 1 - length(find(KMeanMinusGTruth)) / length(find(kMean));
                 strgInclusion = 1 - length(find(strgMinusGTruth)) / length(find(strg));
                 
                 %insert results into map
                 obj.kMeanInclusionMap = mapInsert(obj.kMeanInclusionMap, isName, kMeanInclusion);
                 obj.strgInclusionMap = mapInsert(obj.strgInclusionMap, isName, strgInclusion);
            end
        end
        %%
        function obj = processLesionAhaSegmentMasks(obj)
            for k = 1 : length(obj.isKS)
                ahaMask = obj.ahaSegmentsMaskMap(obj.isKS{k});
                gndTrthMask = obj.groundTruthMaskMap(obj.isKS{k});
                normalMask = obj.normalMaskMap(obj.isKS{k});
                ahaLesionMask = zeros(size(gndTrthMask));
                ahaNormalMask = zeros(size(gndTrthMask));
                %for aha lesion: remove segments without common voxels with ground truth
                %for aha normal: only keep segment with the most important
                %number of common voxel with normal mask defined by expert
                maxNbCommonVoxels = 0;
                for m = 1 : max(ahaMask(:))
                    tmp = ahaMask;
                    tmp(tmp ~= m) = 0;
                    tmp(tmp == m) = 1;
                    segInterGndTruth = tmp .* gndTrthMask;
                    segInterNormal = tmp .* normalMask;
                    
                    if (max(segInterGndTruth(:)))
                        ahaLesionMask = ahaLesionMask + tmp .* m;
                    end
                    
                    nbCommonVoxels = find(segInterNormal);
                    if (nbCommonVoxels > maxNbCommonVoxels)
                        ahaNormalMask = tmp .* m;
                    end
                    
                end
                obj.lesionAhaSegmentsMaskMap = mapInsert(obj.lesionAhaSegmentsMaskMap, obj.isKS{k}, ahaLesionMask);
                obj.normalAhaSegmentsMaskMap = mapInsert(obj.normalAhaSegmentsMaskMap, obj.isKS{k}, ahaNormalMask);
            end
        end%processLesionAhaSegmentMasks
    end% method (Access = protected)
    
end

