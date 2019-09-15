classdef SegmentationToolAutoTempRegionGrowing < segmentationToolSTMS
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        timeCurveSumMap;
        seedsMaskMap;
        seedCriterion;
        thresholdType;
    end
    
    methods (Access = public)
        function obj = prepare(obj, patientPath, opt)
            obj.seedCriterion = opt.seedCriterion;
            obj.thresholdType = opt.thresholdType;
            obj.prepare@segmentationToolSTMS(patientPath, opt);
            if isfield(opt, 'maskPath')
                obj.loadMask(opt.maskPath)
            end
        end
        %%
        function run(obj)
            obj.processTimeCurvesSum();
            
            for k = 1 : length(obj.slcKS)
                curSumMap = obj.timeCurveSumMap(char(obj.slcKS(k)));
                curCtcSet = obj.ctcSetMap(char(obj.slcKS(k)));
                curMask = obj.maskMap(char(obj.slcKS(k)));
                [H, W] = size(curMask);
                curLabeledImg = zeros(H, W);
                seedsMask = zeros(H, W);
                labelCtr = 1;
%                 rScale = obj.stmsOpt.rScale;
%                 while max(curMask(:))
                    curSeedPos = obj.searchNewSeed(curSumMap, curMask);
                    if curSeedPos.x == -1
                        obj.labelImgMap = mapInsert(obj.labelImgMap, char(obj.slcKS(k)), zeros(H, W));
                        obj.seedsMaskMap = mapInsert(obj.seedsMaskMap, char(obj.slcKS(k)), zeros(H, W));
                        continue;
                    end
                    seedsMask(curSeedPos.x, curSeedPos.y) = labelCtr;
                    curRoiMask = obj.extendRoi(curSeedPos, curMask, curCtcSet,...
                        obj.calculateThreshold(squeeze(curCtcSet(curSeedPos.x, curSeedPos.y, :))));
                    curMask = curMask - curRoiMask;
                    curSumMap = curSumMap .* curMask;
                    curLabeledImg = curLabeledImg + curRoiMask .* labelCtr;
                    labelCtr = labelCtr + 1;
%                 end
                 % add curLabeledImg to the labelImgMap
                if ~isa(obj.labelImgMap,'containers.Map')% create map if does not exists
                    obj.labelImgMap = containers.Map(char(obj.slcKS(k)), curLabeledImg) ;
                else % else insert into map
                    obj.labelImgMap(char(obj.slcKS(k))) = curLabeledImg;
                end
                
                % add curLabeledImg to the labelImgMap
                if ~isa(obj.seedsMaskMap,'containers.Map')% create map if does not exists
                    obj.seedsMaskMap = containers.Map(char(obj.slcKS(k)), seedsMask) ;
                else % else insert into map
                    obj.seedsMaskMap(char(obj.slcKS(k))) = seedsMask;
                end
            end
            if obj.stmsOpt.merge
                obj.mergeRois();
            end
        end%run
        %%
        function processTimeCurvesSum(obj)
            for k = 1 : length(obj.slcKS)
                curMask = obj.maskMap(char(obj.slcKS(k)));
                curCtcSet = obj.ctcSetMap(char(obj.slcKS(k)));
                myoAvgCurve = obj.processAverageTimeCurve(curCtcSet, curMask);
                upTimeLim = find(myoAvgCurve == max(myoAvgCurve), 1, 'first');
                [H, W] = size(curMask); 
                curSumMap = zeros(H, W);
                for l = 1 : H
                    for m = 1 : W
                        if curMask(l, m)
                            curSumMap(l, m) = sum(curCtcSet(l, m, obj.stmsOpt.lwTCrop:obj.stmsOpt.upTCrop));
                        end
                    end
                end
                % add it to the map
                if ~isa(obj.timeCurveSumMap,'containers.Map')% create map if does not exists
                    obj.timeCurveSumMap = containers.Map(char(obj.slcKS(k)), curSumMap) ;
                else % else insert into map
                    obj.timeCurveSumMap(char(obj.slcKS(k))) = curSumMap;
                end
            end
        end%processTimeCurvesSum
        %%
        function roiMask = extendRoi(obj, seedPos, searchMask, ctcSet, rScale)
            
            seedCtc = squeeze(ctcSet(seedPos.x, seedPos.y, :));
            ubCtc = seedCtc +  rScale;
            lbCtc = seedCtc -  rScale;
            [H, W, T] = size(ctcSet);
            
            roiMask = zeros(H, W);
            roiMask(seedPos.x, seedPos.y) = 1;
            
            d = strel('disk', 8);
            out = 0;
            
            while ~out
                tmp = imdilate(roiMask, d) - roiMask;
                tmp = tmp .* searchMask;
                for k = 1 : H
                    for l = 1 : W
                        try
                        if tmp(k, l)
                            tmpCtc = squeeze(ctcSet(k, l, :));
                            if min(ubCtc(obj.stmsOpt.lwTCrop:obj.stmsOpt.upTCrop) - tmpCtc(obj.stmsOpt.lwTCrop:obj.stmsOpt.upTCrop)) < 0 || min(tmpCtc(obj.stmsOpt.lwTCrop:obj.stmsOpt.upTCrop) - lbCtc(obj.stmsOpt.lwTCrop:obj.stmsOpt.upTCrop)) < 0
                                tmp(k, l) = 0;
                            end
                        end
                        catch e
                            fprintf('error');
                        end
                    end
                end
                % end region growing if max number of voxel region is reached
                % or if mask does not grow anymore
                if ~max(((tmp(:) + roiMask(:)).* searchMask(:)) - roiMask(:))
                    roiMask = (roiMask + tmp) .* searchMask;
                    out = 1; % end of region growing
                end
                roiMask = (roiMask + tmp) .* searchMask;
            end
        end%extendRoi
        %%
        function mergeRois(obj)
            for k = 1 : length(obj.slcKS)
                curLabeledImg = obj.labelImgMap(char(obj.slcKS(k)));
                curCtcSet = obj.ctcSetMap(char(obj.slcKS(k)));
                [H, W, Z] = size(curCtcSet);
                for l = 1 : max(curLabeledImg(:))
                    pos = find(curLabeledImg == l);
                    [x, y] = ind2sub([H, W], pos);
                    for m = 1 : Z
                        tmp = 0;
                        for n = 1 : length(x)
                            tmp = tmp + squeeze(curCtcSet(x(n), y(n), :));
                        end
                        avgLabeledCtc(l, :) = tmp./length(x);
                    end
                end
                
                for l = max(curLabeledImg(:)) : -1 : 2
                    curCtc = avgLabeledCtc(l, :);
                    ubCtc = curCtc +  obj.stmsOpt.rScale / 2;
                    lbCtc = curCtc -  obj.stmsOpt.rScale / 2;
                    for m = l - 1  : -1 : 1
                        tmpCtc = avgLabeledCtc(m, :);
                        if min(ubCtc(obj.stmsOpt.lwTCrop:obj.stmsOpt.upTCrop) - tmpCtc(obj.stmsOpt.lwTCrop:obj.stmsOpt.upTCrop)) > 0 && min(tmpCtc(obj.stmsOpt.lwTCrop:obj.stmsOpt.upTCrop) - lbCtc(obj.stmsOpt.lwTCrop:obj.stmsOpt.upTCrop)) > 0
                            curLabeledImg(curLabeledImg == l) = m;
                            l = l - 1;
                        end
                    end
                end
                
                labelCounter = 1;
                for l = 1 : max(curLabeledImg(:))
                    if ~isempty(curLabeledImg(curLabeledImg == l))
                        curLabeledImg(curLabeledImg == l) = labelCounter;
                        labelCounter = labelCounter + 1;
                    end
                end
                obj.labelImgMap(char(obj.slcKS(k))) = curLabeledImg;
            end
            
        end%mergeRois
        %%
        function thresh = calculateThreshold(obj, seedCtc)
            switch obj.thresholdType
                case 'absolute'
                    thresh = obj.stmsOpt.rScale;
                case 'percentage'
                    scale = max(seedCtc(:)) - min(seedCtc(:));
                    thresh = scale * obj.stmsOpt.rScale / 100;
            end
        end%calculateThreshold
        %%
        function newSeedPos = searchNewSeed(obj, sumMap, mask)
            
            %initialy search seeds in the core of the myocardium to avoid 
            % user myocardium segmentation errors
            subMask = imerode(mask, strel('disk', 1));
            tmp = sumMap .* subMask;
            if max(tmp(:))
                sumMap = tmp;
            end
            
            %if no more voxels seeds are in the center, then search around
            %
            try
                switch obj.seedCriterion    
                    case 'min_area_under_curve'
                        curSeed = find( (sumMap == min(sumMap(sumMap > 0)))...
                            ,1, 'first');
                    case 'max_area_under_curve'
                        curSeed = find( (sumMap == max(sumMap(sumMap > 0)))...
                            ,1, 'first');
                end
                [newSeedPos.x, newSeedPos.y] = ind2sub(size(sumMap), curSeed);
            catch
                newSeedPos.x = -1; newSeedPos.y = -1;
            end
            
        end%searchNewSeed
        
        % getters
        function labeledSlcImg = getLabledSlcImg(obj, slcName)
            labeledSlcImg = obj.labelImgMap(slcName);
        end %getLabledSlcImg
        %%
        function seedsMask = getSeedsMask(obj, slcName)
            seedsMask = obj.seedsMaskMap(slcName);
        end%getSeedsMask
        %%
        function AUCMask = getAUCMask(obj, slcName)
            AUCMask = obj.timeCurveSumMap(slcName);
        end%
        %%
        %setters
        function setLabledSlcImg(obj, slcName, labeledSlcImg)
            obj.labelImgMap(slcName) = labeledSlcImg;
        end
        %%
        function obj = setMaskMap(obj, maskMap)
            obj.maskMap = maskMap;
        end
        
    end
    methods (Access = protected)
        %%
        function obj = loadMask(obj, path)
            if nargin < 2
                obj = obj.loadMask@segmentationToolSTMS();
                return;
            end
            %
            for k = 1 : obj.slcPathMap.length
                slcName = char(obj.slcKS(k));
                % load slice ctcSet
                try
                    mask = loadmat(fullfile(path, slcName, 'mask.mat'));
                catch e
                    obj.lgr.err('could not load mask');
                end
                obj.maskMap = mapInsert(obj.maskMap, slcName, mask);
            end
        end%loadMask
    end%
    
end

