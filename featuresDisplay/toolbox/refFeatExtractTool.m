classdef refFeatExtractTool < featuresTool
    %mother class of features extraction tools
    
    properties (Access = protected)
        slcLesionMap;
        slcNormalMap;
        lesionFeatVectMap;
        normalFeatVectMap;
        lesionTicMap;
        normalTicMap;
    end% (Access = public)
    
    methods (Access = protected)
        function obj = loadSlcROIMask(obj)
            %lesion
            for k = 1 : obj.slcPathMap.length;
                isName = char(obj.slcKS(k));
                try
                    mask = loadmat(fullfile(obj.patientPath, 'segmentation', 'ManualMultiRoiMapDisplay', ['labelsMask_' isName '.mat']));
                    xmlStrct = xml2struct(fullfile(obj.patientPath, 'segmentation', 'ManualMultiRoiMapDisplay', ['roiInfo_' isName '.xml']));
                    roisInfo = xmlStrct.roisInfo;
                    lesionId = nan; normalId = nan;
                    %
                    if ~iscell(roisInfo.roi)
                        roisInfo.roi = {roisInfo.roi};
                    end
                    for m = 1 : length(roisInfo.roi)
                        switch roisInfo.roi{m}.name.Text
                            case 'lesion'
                                lesionId = str2double(roisInfo.roi{m}.id.Text);
                            case 'normal'
                                normalId = str2double(roisInfo.roi{m}.id.Text);
                        end
                    end
                    lesionMask = mask;
                    lesionMask(mask ~= lesionId) = 0; lesionMask = lesionMask ./ lesionId;
                    normalMask = mask;
                    normalMask(mask ~= normalId) = 0; normalMask = normalMask ./ normalId;
                catch e
                    cprintf('orange', ...
                        'refFeatExtractTool:loadSlcROIMask no lesion mask found in %s\n',...
                        fullfile(obj.patientPath, 'segmentation', 'lesion', isName));
                    [H, W, ~] = size(obj.slcSerieMap(isName));
                    mask = zeros(H, W);
                end
                obj.slcLesionMap = mapInsert(obj.slcLesionMap, isName, lesionMask);
                obj.slcNormalMap = mapInsert(obj.slcNormalMap, isName, normalMask);
            end%for
        end%loadSlcROIMask(obj)

        function obj = processFeatPoints(obj)
            for k = 1 : length(obj.slcKS)
                imSerie = obj.slcSerieMap(char(obj.slcKS(k)));
                lesionMask = obj.slcLesionMap(char(obj.slcKS(k)));
                normalMask = obj.slcNormalMap(char(obj.slcKS(k)));
                
                opt.lwTCrop = 4;
                opt.upTCrop = 50;% size(imSerie, 3);
                avgLesionTic = obj.processRoiAvgCurve(lesionMask, imSerie, opt);
                avgNormalTic = obj.processRoiAvgCurve(normalMask, imSerie, opt);
                
                lesionVect = obj.processTicFeat(avgLesionTic, lesionMask);
                normalVect = obj.processTicFeat(avgNormalTic, normalMask);
                
                % add it to the map
                if ~isa(obj.lesionFeatVectMap,'containers.Map')% create map if does not exists
                    obj.lesionFeatVectMap = containers.Map(char(obj.slcKS(k)), lesionVect) ;
                else % else insert into map
                    obj.lesionFeatVectMap(char(obj.slcKS(k))) = lesionVect;
                end
                
                % add it to the map
                if ~isa(obj.normalFeatVectMap,'containers.Map')% create map if does not exists
                    obj.normalFeatVectMap = containers.Map(char(obj.slcKS(k)), normalVect) ;
                else % else insert into map
                    obj.normalFeatVectMap(char(obj.slcKS(k))) = normalVect;
                end
                
                % add it to the map
                if ~isnan(avgLesionTic)
                    if ~isa(obj.lesionTicMap,'containers.Map')% create map if does not exists
                        obj.lesionTicMap = containers.Map(char(obj.slcKS(k)), avgLesionTic) ;
                    else % else insert into map
                        obj.lesionTicMap(char(obj.slcKS(k))) = avgLesionTic;
                    end
                end
                
                % add it to the map
                if ~isnan(avgNormalTic)
                    if ~isa(obj.normalTicMap,'containers.Map')% create map if does not exists
                        obj.normalTicMap = containers.Map(char(obj.slcKS(k)), avgNormalTic) ;
                    else % else insert into map
                        obj.normalTicMap(char(obj.slcKS(k))) = avgNormalTic;
                    end
                end
            end %for k = 1...
            
            
        end%processFeatPoints
        
        function avgCurve = processRoiAvgCurve(obj, roiMask, imSerie, opt)
            [H, W, T] = size(imSerie);
            
            pos = find(roiMask == 1);
            [x, y] = ind2sub([H, W], pos);
            avgCurve = zeros(1, T);
            
            tmp = 0;
            if length(x) > 0
                for n = 1 : length(x)
                    tmp = tmp + squeeze(imSerie(x(n), y(n), opt.lwTCrop:opt.upTCrop));
                end
                avgCurve = tmp ./ length(x);
            else
                avgCurve = ones(opt.upTCrop - opt.lwTCrop + 1, 1) .* nan;
            end
        end%calculateRoiAvgCurve
        
        function ticFeatures = processTicFeat(obj, curve, mask)
            if isnan(curve)
                ticFeatures = zeros(6,1);
                return;
            end
            ticSlope = diff(curve);
            
            ticFeatures = ...
                [
                max(curve); %peakVal
                find(curve == max(curve), 1, 'first');% TTP
                length(mask(mask==1));% region surface
                sum(curve);%AUC
                max(ticSlope(:)); %maxslope
                find(ticSlope == max(ticSlope(:)), 1, 'first'); %maxslope pos
                ];
        end%processTicFeat
    end% methods (Access = protected)
    
    methods (Access = public)
        
        function obj = run(obj)
            obj = obj.loadSlcSerie();
            obj = obj.loadSlcROIMask();
            obj = obj.processFeatPoints();
        end%run
        
        %getters
        function tic = getRoiAvgTic(obj, slcName, className)
            switch className
                case 'lesion'
                    tic = obj.lesionTicMap(slcName);
                case 'normal'
                    tic = obj.normalTicMap(slcName);
                otherwise
                    cprintf('orange',...
                        'no features vect for slice %s\n', slcName);
            end
        end%getRoiAvgTic
        
        function featVect = getRoiFeatures(obj, slcName, className, featuresNameKS)
            switch className
                case 'lesion'
                    tmpVect = obj.lesionFeatVectMap(slcName);
                case 'normal'
                    tmpVect = obj.normalFeatVectMap(slcName);
                otherwise
                    cprintf('orange',...
                        'no time intensity curve for slice %s', slcName);
            end
            for k = 1 : length(featuresNameKS)
                switch char(featuresNameKS(k))
                    case 'PeakVal'
                        featVect(k) = tmpVect(1);
                    case 'TTP'
                        featVect(k) = tmpVect(2);
                    case 'roiSurface'
                        featVect(k) = tmpVect(3);
                    case 'AUC'
                        featVect(k) = tmpVect(4);
                    case 'maxSlope'
                        featVect(k) = tmpVect(5);
                    case 'maxSlopePos'
                        featVect(k) = tmpVect(6);
                end
            end
            
        end%getRoiFeat
        
        function normalMask = getNormalMask(obj, slcName)
            normalMask = obj.slcNormalMap(slcName);
        end%getNormalMask
        
        function lesionMask = getLesionMask(obj, slcName)
            lesionMask = obj.slcLesionMap(slcName);
        end%getLesionMask
        
    end%methods (Access = public)
    
end