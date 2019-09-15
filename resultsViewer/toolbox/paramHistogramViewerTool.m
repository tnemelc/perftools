classdef paramHistogramViewerTool < resultViewerTool
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        paramMatrixName;
        xbins;
        step;
        dispMode;
        eraseMode;
        roiMode;
        treshMap;
        statsMap;
        lblImageMap;
        slcStatMap;
    end
    
    methods (Access = public)
        function prepare(obj, opt)
            obj.prepare@resultViewerTool(opt);
            obj.paramMatrixName = opt.parameterName;
            obj.loadParametersMap();
            obj.loadLabeledMap();
            obj.loadpeakImg();
            obj.step = opt.step;
            obj.dispMode = 'mask';
            obj.eraseMode = 'off';
            obj.roiMode = 'off';
            cprintf('paramHistogramViewerTool: keys shortcuts\n b: bounds mode\n m: mask mode\n e: erase mode on\n r: erase mode off')
            
        end%prepare
        
        function run(obj)
            fm = figureMgr.getInstance();
            for k = 1 : obj.slcPathMap.length;
               h = fm.newFig(char(obj.slcKS(k)));
               set(h, 'KeyPressFcn', {@obj.onKeyPressCb, char(obj.slcKS(k))});
               curMap = obj.paramMatrixMap(char(obj.slcKS(k))); %title([char(obj.slcKS(k)) ' ' obj.paramMatrixName]);
               subplot(1, 2, 1); h = imagesc(overlay(obj.correctImage(obj.peakImgMap(char(obj.slcKS(k)))), curMap, 'jet')); axis off image;
               set(h, 'ButtonDownFcn',  {@obj.onImgBnClickCb, char(obj.slcKS(k))});
               obj.dispParamHisto(char(obj.slcKS(k)));
               h = findobj(gca,'Type', 'patch');
               set(h, 'ButtonDownFcn',  {@obj.onHistBnClickCb, char(obj.slcKS(k))});
            end
        end%run
        
        function retVal = save(obj, path, opt)
            retVal = -1;
            fm = figureMgr.getInstance();
            for k = 1 : obj.slcPathMap.length;
                curSlcName = char(obj.slcKS(k));
                %root.(curSlcName).threshold = obj.treshMap(curSlcName);
                root.(curSlcName).peakImagePos = obj.peakPosMap(curSlcName);
                %root.(curSlcName).stats = obj.statsMap(curSlcName);
                struct2xml(struct('summary', root), fullfile(path, 'summary.xml'));
                fm.exportAxes(curSlcName, path);
                fm.save(curSlcName, path);
                savemat(fullfile(path, [obj.paramMatrixName '_' curSlcName '.mat']), obj.paramMatrixMap(curSlcName));
            end
            retVal = obj.mapVal2txt(path);
            retVal = obj.roiVal2txt(path, opt.paramMapName);
        end%save
        
        function retVal = mapVal2txt(obj, path)
            retVal = 0;
            for k = 1 : obj.slcPathMap.length;
                curSlcName = char(obj.slcKS(k));
                curMap = obj.paramMatrixMap(char(obj.slcKS(k)));
                try
                    threshVal = obj.treshMap(curSlcName);
                catch
                    threshVal = -1;
                end
                lowerVal = curMap((curMap > 0) & (curMap < threshVal));
                strLower = sprintf('nbPts:%d\n', numel(lowerVal));
                for l = 1 : numel(lowerVal)
                    strLower = sprintf('%s%0.02f;', strLower, lowerVal(l));
                end
                strLower = [strLower '\n'];
                fd = fopen(fullfile(path, ['lowerThreshValues_' curSlcName '.txt']), 'w');
                try 
                    fprintf(fd, strLower);
                catch
                    fclose(fd);
                    retVal = -2;
                end
                fclose(fd);
                
                upperVal = curMap(curMap >= threshVal);
                strUpper = sprintf('nbPts:%d\n', numel(upperVal));
                for l = 1 : numel(upperVal)
                    strUpper = sprintf('%s%0.02f;', strUpper, upperVal(l));
                end
                strUpper = [strUpper '\n'];
                fd = fopen(fullfile(path, ['upperThreshValues_' curSlcName '.txt']), 'w');
                try fprintf(fd, strUpper); catch; fclose(fd); retVal = -2;end
                fclose(fd);
                
                
                fd = fopen(fullfile(path, ['ThreshValues_' curSlcName '.txt']), 'w');
                try fprintf(fd, 'lower Values\n%s\nupperValues\n%s\n', strLower, strUpper); catch; fclose(fd); retVal = -2;end
                fclose(fd);
                
            end
        end%mapVal2txt
        
        function retVal = roiVal2txt(obj, path, paramMapName)
            retVal = 0;
            for k = 1 : obj.slcPathMap.length
                curSlcName = char(obj.slcKS(k));
                curMap = obj.paramMatrixMap(char(obj.slcKS(k)));
                curLabeledImg = obj.lblImageMap(curSlcName);
                nbRoi = max(curLabeledImg(:));
                
                fid = fopen(fullfile(path, ['roiValues_'  curSlcName, '_', paramMapName '.txt']), 'w');
                fprintf(fid, 'parameter: %s\n', paramMapName);
                try
                    for l = 1 : nbRoi
                        roiValueTab = curMap(curLabeledImg == l);
                        fprintf(fid, 'roi id: %d, surface: %d (voxels)\n', l, length(roiValueTab));
                        fprintf(fid, 'parametric roi values: \n');
                        
                        str = '';
                        for m = 1 : length(roiValueTab)
                            str = sprintf('%s%0.02f;', str, roiValueTab(m));
                        end
                        fprintf(fid, '%s\n', str);
                    end
                catch e
                    fclose(fid);
                    obj.setFooterStr('paramHistogramViewerTool:roiVal2txt: x_x something bad happened during saving');
                    rethrow(e);
                end
                fclose(fid);
            end
        end%roiVal2txt
        
    end%methods (Access = public)
    
    methods (Access = protected)
        function loadParametersMap(obj)
            for k = 1 : obj.slcPathMap.length;
                tmpMatrix = loadmat(fullfile(obj.slcPathMap(char(obj.slcKS(k))), [obj.paramMatrixName '.mat']));
                if ~isa(obj.paramMatrixMap,'containers.Map')% create map if does not exists
                    obj.paramMatrixMap = containers.Map(char(obj.slcKS(k)), tmpMatrix);
                else % else insert into map
                    obj.paramMatrixMap(char(obj.slcKS(k))) = tmpMatrix;
                end
            end
        end% loadParametersMap
        
        function loadLabeledMap(obj)
            for k = 1 : obj.slcPathMap.length
                tmpPath = fileparts(fileparts(fileparts(fileparts(obj.slcPathMap(char(obj.slcKS(k)))))));
                tmpPath = fullfile(tmpPath, 'segmentation', 'ManualMultiRoiMapDisplay');
                tmpImg = loadmat(fullfile(tmpPath, ['labelsMask_' char(obj.slcKS(k)) '.mat']));
                obj.lblImageMap = mapInsert(obj.lblImageMap, char(obj.slcKS(k)), tmpImg);
            end
        end%loadLabeledMap
        
        function onHistBnClickCb(obj, arg1, ~, slcName)
            axesHandle  = get(arg1, 'Parent');
            coordinates = get(axesHandle, 'CurrentPoint');
            if ~coordinates(1); coordinates(1) = 1; end
            if ~coordinates(2); coordinates(2) = 1; end
            
            thresh = obj.xbins(find(obj.xbins >= coordinates(1), 1, 'first'));
            thresh = thresh - obj.step / 2;
%             lwBound = thresh - obj.step * 3 / 2;
            obj.treshMap = mapInsert(obj.treshMap, slcName, thresh);
            curMap = obj.paramMatrixMap(slcName);
            %curMap(curMap < lwBound) = 0;
            
            %histogram
            ax = subplot(1, 2, 2);
            cla;
            obj.xbins = 0 -  obj.step / 2 : obj.step : max(curMap(:));
            hist(ax, curMap(curMap ~= 0), obj.xbins); 
            curMap(curMap > thresh) = 0;
            hist(ax, curMap(curMap ~= 0), obj.xbins); 
            h = get(ax, 'children');
            
            set (h(2), 'facecolor', [44 160 44] ./ 255);  % set a new RGB face color
            set (h(1), 'facecolor', [255 127 14] ./ 255);  % set a new RGB face color
            h = findobj(gca,'Type','patch');
            set(h, 'ButtonDownFcn',  {@obj.onHistBnClickCb, slcName});
            ylim(ax,[0 100]);
            
            %image
            subplot(1, 2, 1); 
            switch obj.dispMode
                case 'mask'
                    h = imagesc(overlay(obj.correctImage(obj.peakImgMap(slcName)), curMap, 'jet')); 
                case 'bound'
                    h = imagesc(obj.correctImage(obj.peakImgMap(slcName))); colormap gray;
                    obj.plotThreshDefinedRoiBounds(curMap, obj.paramMatrixMap(slcName));
            end%switch
            axis off image;
            set(h, 'ButtonDownFcn',  {@obj.onImgBnClickCb, slcName});
            obj.optimFocus(slcName);
            
            obj.processSlcStat(slcName);
        end%onHistBnClickCb
        
        function onImgBnClickCb(obj, ~, ~, slcName)
            switch obj.eraseMode
                case 'off'
                    h = obj.dispParamMap(slcName);
                case 'on'
                    obj.startErase(slcName)
            end
        end%onImgBnClickCb
        
        function axesHdle = dispParamMap(obj, slcName)
            curMap = obj.paramMatrixMap(slcName);
            pkImg = obj.peakImgMap(slcName);
            subplot(1, 2, 1); axesHdle = imagesc(overlay(obj.correctImage(pkImg), curMap, 'jet')); axis off image;
            obj.optimFocus(slcName);
        end%dispParamMap
        
        function axesHdle = dispParamHisto(obj, slcName)
            paramMap = obj.paramMatrixMap(slcName);
            obj.xbins = 0 : obj.step : max(paramMap(:));
            axesHdle = subplot(1, 2, 2); cla; hold on;
            hist(axesHdle, paramMap(paramMap ~= 0), obj.xbins);
            xlim([0 max(paramMap(:))]);
        end%dispParamHisto
        
        function displayLabeledRegionHistogram(obj, slcName)
%             for k = 1 : obj.slcPathMap.length
%                 slcName = char(obj.slcKS(k));
                subplot(1, 2, 1);
                imagesc(obj.correctImage(obj.peakImgMap(slcName))); colormap gray;
                axis off image;
                lblImg = obj.lblImageMap(slcName);
                nbRois = max(lblImg(:));
                h = figure; cmap = colormap(jet(nbRois)); close(h)
                obj.plotUserDefinedRoiBounds(lblImg, cmap);
                obj.optimFocus(slcName);
                obj.dispLabeledRoiHistograms(slcName, lblImg, cmap);
%             end
        end%displayLabeledRegionHistogram
        
        function dispLabeledRoiHistograms(obj, slcName, lblImg, cmap)
            paramMap = obj.paramMatrixMap(slcName);
            obj.xbins = 0 : obj.step : max(paramMap(:));
            axesHdle = subplot(1, 2, 2); cla; hold on;
            a = paramMap(paramMap ~= 0);
            hist(a, obj.xbins);
            mainHistHdle = get(gca, 'children');
            xlim([-obj.step / 2 max(paramMap(:))]);
            nbRoi = max(lblImg(:));
            
            for k = 1 : nbRoi
                maskParamMap = lblImg;
                maskParamMap(maskParamMap ~= k) = 0;
                maskParamMap = maskParamMap ./ k;
                maskParamMap = maskParamMap  .* paramMap;
                hist(gca, maskParamMap(maskParamMap ~= 0), obj.xbins);
            end
            
            h = get(gca, 'children');
            for k = 1 : nbRoi + 1
                if h(k) == mainHistHdle;
                    set (h(k), 'facecolor', ones(1, 3) .* 0.95);
                else
                    set (h(k), 'facecolor', cmap((nbRoi + 1) - k, :));
                    set (h(k), 'facealpha', 1);
                end
            end
        end%dispLabeledRoiHistograms
        
        
        function startErase(obj, slcName)
            set(gcf, 'WindowButtonMotionFcn', {@obj.erase, slcName});
            set(gcf, 'WindowButtonUpFcn', {@obj.stopEraseCb, slcName});
            set(gcf,'Pointer', 'circle');
        end%startErase
        
        function erase(obj, ~, ~, slcName)
            paramMat = obj.paramMatrixMap(slcName);
            %tmpParamMat = paramMat;%filterMask(obj, paramMat);
            coordinates = get(gca, 'CurrentPoint');
            coordinates = floor(coordinates(1, 1:2));
            if ~coordinates(1); coordinates(1) = 1; end
            if ~coordinates(2); coordinates(2) = 1; end
            
            paramMat(coordinates(2) - 1, coordinates(1)) = 0;
            paramMat(coordinates(2), coordinates(1) - 1) = 0;
            paramMat(coordinates(2) - 1, coordinates(1) - 1) = 0;
            paramMat(coordinates(2) - 1, coordinates(1) + 1) = 0;
            paramMat(coordinates(2), coordinates(1)) = 0;
            paramMat(coordinates(2) + 1, coordinates(1) - 1) = 0;
            paramMat(coordinates(2) + 1, coordinates(1)) = 0;
            paramMat(coordinates(2), coordinates(1) + 1) = 0;
            paramMat(coordinates(2) + 1, coordinates(1) + 1) = 0;
            %              newLabeledImg = paramMat - (filterMask(obj, paramMat) - paramMat);
            %              obj.segTool.setLabledSlcImg(slcName, newLabeledImg);
            %              obj.segTool.setMask(slcName, newLabeledImg > 0);
            obj.paramMatrixMap(slcName) = paramMat;
            xlim = get(gca, 'XLim'); ylim = get(gca, 'YLim');
            axes(gca);
            imHdle = imagesc(paramMat);axis off image;
            set(gca, 'XLim', xlim); set(gca, 'YLim', ylim);
            set(imHdle, 'ButtonDownFcn', {@obj.onBnClickCb, slcName});
        end%eraseCb
        
        
        function stopEraseCb(obj, ~, ~, slcName)
            set(gcf, 'WindowButtonUpFcn', '');
            set(gcf, 'WindowButtonMotionFcn', '');
            set(gcf,'Pointer', 'arrow');
            h = obj.dispParamMap(slcName);
            set(h, 'ButtonDownFcn',  {@obj.onImgBnClickCb, slcName});
            obj.dispParamHisto(slcName);
            subplot(1, 2, 2);
            h = findobj(gca,'Type', 'patch');
            set(h, 'ButtonDownFcn',  {@obj.onHistBnClickCb, slcName});
        end%stopEraseCb
        
        function onKeyPressCb(obj, ~, arg, slcName)
            obj.onKeyPressCb@resultViewerTool([], arg);
            switch arg.Key
                case 'b'
                    obj.dispMode = 'bound';
                    cprintf('bound mode activated\n');
                case 'm'
                    obj.dispMode = 'mask';
                    cprintf('mask mode activated\n');
                case 'e'
                    switch obj.eraseMode
                        case 'off'
                            obj.eraseMode = 'on';
                            obj.dispMode = 'mask';
                            cprintf('mask mode activated\n');
                            cprintf('erase mode activated\n');
                        case 'on'
                            obj.eraseMode = 'off';
                            cprintf('erase mode deactivated\n');
                    end
                case 'r'
                    switch obj.roiMode
                        case 'off'
                            obj.roiMode = 'on';
                            obj.displayLabeledRegionHistogram(slcName)
                            cprintf('roi mode activated\n');
                        case 'on'
                            obj.roiMode = 'off';
                            cprintf('roi mode deactivated\n');
                    end
                    return;
            end
            
            curMap = obj.paramMatrixMap(slcName);
            subplot(1, 2, 1); h = imagesc(overlay(obj.correctImage(obj.peakImgMap(slcName)), curMap, 'jet')); axis off image;
            set(h, 'ButtonDownFcn',  {@obj.onImgBnClickCb, slcName});
            obj.optimFocus(slcName);
        end%onKeyPressCb
        
        function plotThreshDefinedRoiBounds(obj, map, mask)
            map(map > 0) = 1;
            
            %first plot mask bounds
            [B, ~] = bwboundaries(imdilate(mask, strel('disk', 1)));
            subplot(1, 2, 1); hold on;
            for l = 1 : length(B)
                boundary = B{l};
                if size(boundary, 1) > 10
                    obj.smoothPlot(boundary, [0 0 1]);
                end
            end
            % then ischemia (only) ROIs
            if nargin == 3
                cmap = [255 127 14] ./ 255;
                map = imdilate(map, strel('disk', 1)) .* mask;
            else
                cmap = [44 160 44] ./ 255;
                map = imerode(map, strel('disk', 1));
            end
            [B, ~] = bwboundaries(map, 'noholes');
            subplot(1, 2, 1); hold on;
            for l = 1 : length(B)
                boundary = B{l};
                if size(boundary, 1) > 10
                    obj.smoothPlot(boundary, cmap(1, :));
                    %                     plot(boundary(:, 2), boundary(:, 1), 'w', 'LineWidth', 2, 'color', cmap(1, :));
                    if nargin == 3
                        mask(find(map > 0)) = 0;
                        %                         obj.plotThreshDefinedRoiBounds(mask);
                    end
                end
            end
            
        end%plotThreshDefinedRoiBounds
        
        function plotUserDefinedRoiBounds(obj, mask, cmap)
            nbRoi = size(cmap, 1);
            subplot(1, 2, 1); hold on;
            for k = 1 : nbRoi
                curRoiMask = mask;
                curRoiMask(curRoiMask ~= k) = 0;
                [B, ~] = bwboundaries(imdilate(curRoiMask, strel('disk', 1)));
                for l = 1 : length(B)
                    boundary = B{l};
                    if size(boundary, 1) > 2
                        obj.smoothPlot(boundary, cmap(k, :));
                    end
                end
            end
        end%plotUserDefinedRoiBounds
        
        function smoothPlot(obj, boundaries, cmap)
            x = boundaries(:, 2);
            y = boundaries(:, 1);
            boundaryLength = length(x);
            subSamplingFactor = 2;
            xSubsampled = x(1 : subSamplingFactor : end);
            ySubsampled = y(1 : subSamplingFactor : end);
            numInterpolatingPoints = length(xSubsampled);
            t = 1 : boundaryLength;
            tx = linspace(1, boundaryLength, numInterpolatingPoints);
            px = pchip(tx, xSubsampled, t);
            % Smooth y coordinates.
            py = pchip(tx, ySubsampled, t);
            px = [px px(1)];
            py = [py py(1)];
            plot(px, py, 'LineWidth', 2, 'color', cmap(1, :));
        end%smoothPlot
        
        function optimFocus(obj, slcName)
            mask = obj.paramMatrixMap(slcName);
            mask(mask > 0) = 1;
            margin = 10;
            box = regionprops(logical(mask), 'Area', 'BoundingBox');
            rect = box.BoundingBox; 
            set(gca, 'xlim', [rect(1) - margin , (rect(1) + rect(3) + margin)], 'ylim', [rect(2) - margin, (rect(2) + rect(4) + margin)]);
        end%optimFocus
        
        function processSlcStat(obj, slcName)
            paramMap = obj.paramMatrixMap(slcName);
            thresh = obj.treshMap(slcName);
            
            upParamVect = paramMap(paramMap > thresh);
            lwParamVect = paramMap((paramMap < thresh) & (paramMap > 0));
            
            stats.upper.mean = mean(upParamVect);
            stats.upper.std  = std(upParamVect);
            stats.upper.min  = min(upParamVect);
            stats.upper.max  = max(upParamVect);
            stats.upper.area  = numel(upParamVect);
            
            
            stats.lower.mean = mean(lwParamVect);
            stats.lower.std  = std(lwParamVect);
            stats.lower.min  = min(lwParamVect);
            stats.lower.max  = max(lwParamVect);
            stats.lower.area  = numel(lwParamVect);
            
            stats.upper.ratio  = stats.upper.area / (stats.upper.area + stats.lower.area);
            stats.lower.ratio  = stats.lower.area / (stats.upper.area + stats.lower.area);
            
            
            obj.statsMap = mapInsert(obj.statsMap, slcName, stats);
        end%processSlcStat
        
    end%methods (Access = protected)
end

