classdef SegmentationToolManualMultiRoiMapDisplay < SegmentationToolManualMultiRoi
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        hdlAxes;
        histOpt;
        slcPos;
        roiTypeRb;
        CtrlUI;
        seedsMaskMap;
        lblNameStruct; %struct that contains roi names of the current slice
        roiInfoCell;%Cell that stores roi info (id, name, surface, thresh, seedPos) of the current Slice
        lblNameStructMap; %Map that contains structs of roi names
        roiInfoCellMap;% map that stores roiInfoCell
        parametricMapMap;% Map of spatial parametricMap
        
        
        BoundsOverlayImgMap;
        paramerticMapOverlayImgMap;
        HistogramImgMap;
        timeCurvePlotImgMap;
    end
    
    methods (Access = public)
        
        function obj = prepare(obj, patientPath, opt)
            obj = obj.prepare@SegmentationToolManualMultiRoi(patientPath, opt);
            obj = obj.resetSlcData();
            obj.labelImgMap = [];
            obj.lblNameStructMap = [];
            obj.roiInfoCellMap = [];
        end%prepare
        
        function obj = resetSlcData(obj)
            obj.histOpt.contrast = 1;
            obj.histOpt.brightness = 0;
            obj.lblNameStruct = [];
            obj.hdlAxes = [];
        end%resetSlcData
        
        function run(obj)
            for k = 1 : length(obj.slcKS)
               obj = obj.resetSlcData();
                figHdle = obj.initFigure(char(obj.slcKS(k)));
                waitfor(figHdle);
                
                obj.lblNameStructMap = mapInsert(obj.lblNameStructMap, ...
                                    char(obj.slcKS(k)), obj.lblNameStruct);
                                
                obj.roiInfoCellMap = mapInsert(obj.roiInfoCellMap,...
                                        char(obj.slcKS(k)), obj.roiInfoCell);
                obj.roiInfoCell = [];
            end
        end%run(obj)
        
        function roiChoiceStr = getRoiChoice(obj)
            if get(obj.CtrlUI.roiTypeRb(1), 'Value')
                roiChoiceStr = 'Manual';
            else
                roiChoiceStr = 'roiGrowing';
            end
        end%roiChoice
        
        function treshold = getThreshold(obj)
            treshold = floor(str2num(get(obj.CtrlUI.threshUI, 'string')));
        end%getThreshold
        
        function roiName = getRoiName(obj)
            roiName = get(obj.CtrlUI.roiNameUI, 'String');
        end%getRoiId
        
        function parametricMapName = getParametricMapName(obj)
            parametricMapName = get(obj.CtrlUI.parametricMapUI, 'String');
        end%getParametricMapName
        
        function parametricMap = getParametricMap(obj, slcName, methodName, parameterName)
            try
                parametricMap =  loadmat(fullfile(obj.patientPath, 'deconvolution', ...
                    methodName, slcName, [parameterName '.mat']));
            catch
                cprintf('orange', 'SegmentationToolManualMultiRoiMapDisplay:getParametricMap: could not load parametric map.\n');
                parametricMap = nan;
            end
        end%getParametricMap
        
        function seedMap = getSeedMap(obj, slcName)
            seedMap = obj.seedsMaskMap(slcName);
        end%getSeedMap
        
        function methodName = getMethodName(obj)
            methodName = get(obj.CtrlUI.methodUI, 'String');
        end%getMethodName

        function boundsOverlayImg = getBoundsOverlayImg(obj, slcName)
            boundsOverlayImg = obj.BoundsOverlayImgMap(slcName);
        end%%getBoundsOverlayImgMap
        
        function paramerticMapOverlayImg = getParamerticMapOverlayImgMap(obj, slcName, method)
            paramerticMapOverlayImg = obj.paramerticMapOverlayImgMap(slcName);
        end%%getBoundsOverlayImgMap
        
        function HistogramImg = getHistogramImg(obj, slcName, method)
            HistogramImg = obj.HistogramImg(slcName);
        end%%getBoundsOverlayImgMap
        
        function timeCurvePlotImg = getTimeCurvePlotImg(obj, slcName)
            timeCurvePlotImg = obj.timeCurvePlotImgMap(slcName);
        end%%getBoundsOverlayImgMap
        
        function lblNameStruct = getLblNameStruct(obj, slcName)
            lblNameStruct = obj.lblNameStructMap(slcName);
        end%getLblNameStruct
        %%
        function roiInfoCell = getRoiInfoCell(obj, slcName)
            roiInfoCell = obj.roiInfoCellMap(slcName);
        end%getroiInfoCell
    end%methods (Access = public)
    
    methods (Access = protected)
        function figHdle = initFigure(obj, slcName)
            slcSerie = obj.slcSerieMap(slcName);
            obj.slcPos = 10;
            fm = figureMgr.getInstance();
            figHdle = fm.newFig(slcName); fm.resize(slcName, 2, 2);
            obj.hdlAxes = tight_subplot(1, 2, [.1 .03], [.15 .01], [.01 .01]);
            
            axes(obj.hdlAxes(1));
            h = imagesc(obj.correctImage(slcSerie(:, :, obj.slcPos))); axis off; axis image;
            set(h, 'ButtonDownFcn', {@obj.onImgClick, slcName});
            obj.dispSlicePos(obj.slcPos, size(slcSerie, 3));
            obj.optimFocus(slcName);
            obj.plotSearchMaskBounds(slcName);
            
            set(figHdle,'WindowScrollWheelFcn', {@obj.OnScrollCb, slcName});
            set(figHdle, 'KeyPressFcn', {@obj.onKeyPressCb, slcName});
            
            obj.initFigureControls(slcName);
            parametricMap = obj.getParametricMap(slcName, 'Bayesian', 'mbfMap');
            axes(obj.hdlAxes(2));
            if ~isnan(parametricMap)
                imagesc(overlay(obj.correctImage(slcSerie(:,:, obj.slcPos)), parametricMap));
            else
                imagesc(obj.correctImage(slcSerie(:,:, obj.slcPos)));
            end
            axis off image;
            obj.optimFocus(slcName, obj.hdlAxes(2));
            colormap gray;
        end%initFigure
        
        function initFigureControls(obj, slcName)
            uicontrol('Style', 'pushbutton',...
                'Units',  'normalized',...
                'Position', [0.05 0.05 0.1 0.1],...
                'String', 'add roi',...
                'Callback', {@obj.addRoi, slcName}, ...
                'Visible', 'on');
            
            uicontrol('Style', 'text',...
                'Units',  'normalized',...
                'Position', [0.3 0.1 0.09 0.05],...
                'String', 'RoiName');
            
            obj.CtrlUI.roiNameUI = ...
                uicontrol('Style', 'edit',...
                'Units',  'normalized',...
                'String', 'lesion',...
                'Position', [0.4 0.1 0.1 0.05]);
            
            % Create three radio buttons in the button group.
            % radio buttons
            obj.CtrlUI.roiTypeRb(1) = uicontrol('Style', 'radiobutton', ...
                'Callback', @obj.definitionTypeCb, ...
                'Units',    'normalized', ...
                'Position', [0.2 0.1 0.09 0.05], ...
                'String',   'manual', ...
                'Value',    1, ...
                'Enable', 'on');
            
            obj.CtrlUI.roiTypeRb(2) = uicontrol('Style', 'radiobutton', ...
                'Callback', @obj.definitionTypeCb, ...
                'Units',    'normalized', ...
                'Position', [0.2 0.05 0.09 0.05], ...
                'String',   'roi growing', ...
                'Value',    0, ...
                'Enable', 'off');
            
            uicontrol('Style', 'text',...
                'Units',  'normalized',...
                'Position', [0.3 0.05 0.05 0.05],...
                'String', 'threshold');
            
            obj.CtrlUI.threshUI = ...
                uicontrol('Style', 'edit',...
                'Units',  'normalized',...
                'String', '10',...
                'Position', [0.4 0.05 0.05 0.05],...
                'enable', 'on');
            
            %param map
            if isdir(fullfile(obj.patientPath, 'deconvolution'))
                enableParametricMapUI = 'on';
            else
                enableParametricMapUI = 'off';
            end
            
            uicontrol('Style', 'text',...
                'Units',  'normalized',...
                'Position', [0.5 0.05 0.1 0.05],...
                'String', 'parameteric map');
            
            obj.CtrlUI.parametricMapUI = ...
                uicontrol('Style', 'edit',...
                'Units',  'normalized',...
                'String', 'mbfMap',...
                'Position', [0.61 0.05 0.1 0.05],...
                'enable', enableParametricMapUI,...
                'Callback', {@obj.onParametricMapChanged, slcName});
            
            uicontrol('Style', 'text',...
                'Units',  'normalized',...
                'Position', [0.5 0.1 0.1 0.05],...
                'String', 'method');
            
            obj.CtrlUI.methodUI = ...
                uicontrol('Style', 'edit',...
                'Units',  'normalized',...
                'String', 'Bayesian',...
                'Position', [0.61 0.1 0.1 0.05],...
                'enable', enableParametricMapUI,...
                'Callback', {@obj.onParametricMapChanged, slcName});
            
            %             uicontrol('Style', 'checkbox',...
            %                 'Units',  'normalized',...
            %                 'Position', [0.72 0.1 0.1 0.05],...
            %                 'String', 'map display/boundaries',...
            %                 'Callback', @obj.switchMapDisplay);
            
            %             uicontrol('Style', 'pushbutton',...
            %                 'Units',  'normalized',...
            %                 'Position', [0.72 0.05 0.1 0.05],...
            %                 'String', 'erase roi',...
            %                 'Callback', @obj.startEraseCb);
            
            %OK button
            uicontrol('Style', 'pushbutton',...
                'Units',  'normalized',...
                'Position', [0.85 0.05 0.1 0.1],...
                'String', 'OK',...
                'Callback', {@obj.closeFigCb, slcName});
        end%createFigureButtons
        
        function addRoi(obj, ~, ~, slcName)
            try
                if ~isfield(obj.lblNameStruct, obj.getRoiName)
                    obj.lblNameStruct.(obj.getRoiName) = numel(fieldnames(obj.lblNameStruct)) + 1;
                end
            catch
                obj.lblNameStruct.(obj.getRoiName) = 1;
            end
            switch obj.getRoiChoice()
                case 'Manual'
                    newRoiMask = obj.addRoiManual(slcName);
                    obj.plotSearchMaskBounds(slcName);
                case 'roiGrowing'
                    newRoiMask = obj.addRoiGrowing(slcName);
            end
            searchMask = obj.maskMap(slcName);
            try
                curLblMask = obj.labelImgMap(slcName);
                curLblMask(curLblMask  == obj.lblNameStruct.(obj.getRoiName())) = 0;
                curLblMask = logical(curLblMask);
            catch
                curLblMask = 0;
            end
            
            %limit the mask to the searching area and set its reference value
            newRoiMask = (searchMask - curLblMask) .* newRoiMask .* obj.lblNameStruct.(obj.getRoiName());
            try
                %merge the mask with the other and reinsert it
                curMask  = obj.labelImgMap(slcName);
                curMask(curMask == obj.lblNameStruct.(obj.getRoiName())) = 0;
                newRoiMask = curMask + newRoiMask;
            catch
                %ignore exception silently
            end
            obj.labelImgMap = mapInsert(obj.labelImgMap, slcName, newRoiMask);
            
            obj.plotRoiBoundaries(slcName)
            obj.dispHistograms(slcName);
            obj.plotRegionTimeCurves(slcName);
            obj.updateRoisInfo(slcName);
            obj.dumpRoisInfo(slcName);
        end%addRoi
        
        function mask = addRoiManual(obj, slcName)
            slcSerie = obj.slcSerieMap(slcName);
            
            img = obj.correctImage(slcSerie(:, :, obj.slcPos));
            minVal = min(min(img));
            maxVal = max(max(img));
            img = (img + abs(minVal)) / maxVal - minVal;
            axes(obj.hdlAxes(1));
            mask = roipoly(img);
            try%%seed mask already created?
                seedsMask = obj.seedsMaskMap(slcName);
                %remove old seed
                seedsMask(seedsMask == obj.lblNameStruct.(obj.getRoiName)) = 0;
            catch%no then create new
                seedsMask = zeros(size(mask));
            end
            obj.seedsMaskMap = mapInsert(obj.seedsMaskMap, slcName, seedsMask);
        end%addRoiManual
        
        function mask = addRoiGrowing(obj, slcName)
            [x,y] = ginput(1);
            mask = obj.growRegion(floor([x, y]), slcName);
            try%%seed mask already created?
                seedsMask = obj.seedsMaskMap(slcName);
                %remove old seed
                seedsMask(seedsMask == obj.lblNameStruct.(obj.getRoiName)) = 0;
            catch%no then create new
                seedsMask = zeros(size(mask));
            end
            seedsMask(floor(y), floor(x)) = obj.lblNameStruct.(obj.getRoiName);
            obj.seedsMaskMap = mapInsert(obj.seedsMaskMap, slcName, seedsMask);
            %obj.labelImgMap = mapInsert(obj.labelImgMap, obj.getRoiName(),  mask);
            
        end%addRoiGrowing
        
        function mask = growRegion(obj, seed, slcName)
            axes(obj.hdlAxes(1)); hold all;
            slcSerie = obj.slcSerieMap(slcName);
            searchMask = obj.maskMap(slcName);
            %plot(seed(1), seed(2), '*'); plot(seed(1), seed(2), 'o');
            delta = obj.getThreshold();%floor(get(sldrUI, 'Value'));
            seedCtc = squeeze(slcSerie(seed(2), seed(1), :));
            
            ubCtc = seedCtc + delta;
            lbCtc = seedCtc - delta;
            [H, W, T] = size(slcSerie);
            if ~strcmp(get(gcf, 'CurrentKey'), 'control') ||...
                    ~exist('myoMask', 'var')
                mask = zeros(H, W);
            end
            mask(seed(2), seed(1)) = 1;
            
            d = strel('disk', 2);
            out = 0;
            
            while ~out
                h = figure; plot(ubCtc, '--'); hold all; plot(lbCtc,'--') ;
                tmp = imdilate(mask, d) - mask;
                for k = 1 : H
                    for l = 1 : W
                        if tmp(k, l)
                            tmpCtc = squeeze(slcSerie(k, l, :));
                            if min(ubCtc(1:end) - tmpCtc(1:end)) < 0 || min(tmpCtc(1:end) - lbCtc(1:end)) < 0
                                tmp(k, l) = 0;
                            end
                        end
                    end
                end
                close(h);
                nbCurves = length(find(mask));
                % end region growing if max number of voxel region is reached
                % or if mask does not grow anymore
                if ~max(((tmp(:) + mask(:)).* searchMask(:)) - mask(:)) || ...
                        nbCurves > 2000
                    mask = (mask + tmp) .* searchMask;
                    out = 1; % end of region growing
                else
                    mask = (mask + tmp) .* searchMask;
                end
            end
            
            if nbCurves > 3000
                succes = false;
                msg = sprintf('number of curves is too large : %', nbCurves);
                f = figure; plot(seedCtc);
                mb = msgbox(msg);
                waitfor(mb);
                close(f);
                return;
            end
            
        end%growRegionCb
        
        function corrIm = correctImage(obj, image)
            maxValue = max(image(:));
            lut(1, :) = (0 : maxValue);
            tmp = obj.histOpt.contrast .*  lut(1, :) + obj.histOpt.brightness;
            tmp(tmp < 0) = 0; tmp(tmp > maxValue) = maxValue;
            lut(2, :) = tmp;
            corrIm = zeros(size(image));
            for k = 1 : numel(image)
                corrIm(k) = lut(2, lut(1,:) == image(k));
            end
        end%correctImage
        
        function dispSlicePos(~, slcPos, nbFrames)
            txtPos = [0.85, 0.05];
            text('units','normalized','position', txtPos,'fontsize', 10, 'color', 'white', 'string', sprintf('%d/%d', slcPos, nbFrames));
        end%dispSlicePos
        
        function [rect, margin] = optimFocus(obj, slcName, axisHdle)
            if nargin > 2
                axes(axisHdle);
            end
            mask = obj.maskMap(slcName);
            margin = 10;
            box = regionprops(logical(mask), 'Area', 'BoundingBox');
            rect = box.BoundingBox;
            set(gca, 'xlim', [rect(1) - margin , (rect(1) + rect(3) + margin)], 'ylim', [rect(2) - margin, (rect(2) + rect(4) + margin)]);
        end%optimFocus
        
        function plotSearchMaskBounds(obj, slcName)
            mask = obj.maskMap(slcName);
            %first plot mask bounds
            [B, ~] = bwboundaries(imdilate(mask, strel('disk', 1)));
            hold on;
            for l = 1 : length(B)
                boundary = B{l};
                 if l == 1
                    obj.smoothPlot(boundary, [0 1 0]);
                 else
                     obj.smoothPlot(boundary, [1 0 0]);
                 end
            end 
        end%plotRoiBounds
     
        function smoothPlot(obj, boundaries, cmap, subSamplingFactor)
            if nargin < 4
                subSamplingFactor = 5;
            end
            x = boundaries(:, 2);
            y = boundaries(:, 1);
            boundaryLength = length(x);
            
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
        
        function OnScrollCb(obj, ~, arg, slcName)
            obj.slcPos = floor(obj.slcPos + arg.VerticalScrollCount);
            slcSerie = obj.slcSerieMap(slcName);
            if obj.slcPos < 1
                obj.slcPos = 1;
            end
            if obj.slcPos > size(slcSerie, 3)
                obj.slcPos = size(slcSerie, 3);
            end
            xlim = get(obj.hdlAxes(1), 'XLim');
            ylim = get(obj.hdlAxes(1), 'YLim');
            axes(obj.hdlAxes(1));
            h = imagesc(obj.correctImage(slcSerie(:, :, obj.slcPos)));
            set(h, 'ButtonDownFcn', {@obj.onImgClick, slcName});
            colormap gray; axis off image;
            obj.dispSlicePos(obj.slcPos, size(slcSerie, 3));
            obj.optimFocus(slcName);
            obj.plotSearchMaskBounds(slcName)
            %title (get(editInputDcm, 'String'));
        end%OnScrollCb
        
        function onImgClick(obj, arg1, ~, slcName)
            axesHandle  = get(arg1, 'Parent');
            coordinates = get(axesHandle, 'CurrentPoint');
            coordinates = round(coordinates(1, 1:2));
            if ~coordinates(1); coordinates(1) = 1; end
            if ~coordinates(2); coordinates(2) = 1; end
            x = coordinates(2);
            y = coordinates(1);
            slcSerie = obj.slcSerieMap(slcName);
            figureMgr.getInstance().newFig('TIC_plot');
            plot(squeeze(slcSerie(x, y, :)));
            
        end%onImgClick
        
        function plotRoiBoundaries(obj, slcName)
            slcSerie = obj.slcSerieMap(slcName);
            figureMgr.getInstance().focus(slcName); axes(obj.hdlAxes(2));
            %first display image with map as an overlay
            try
                parametricMap = loadmat(fullfile(obj.patientPath, 'deconvolution', ...
                obj.getMethodName(), slcName, [obj.getParametricMapName() '.mat']));
                imHdle = imagesc(overlay(obj.correctImage(slcSerie(:, :, obj.slcPos)), parametricMap));
                colormap gray;
            catch
                cprintf('orange', 'SegmentationToolManualMultiRoiMapDisplay::plotRoiBoundaries: could not load parametric map\n')
                imHdle = imagesc(obj.correctImage(slcSerie(:, :, obj.slcPos)));
            end
            axis off image;
            obj.optimFocus(slcName, obj.hdlAxes(2));
            set(imHdle, 'ButtonDownFcn', {@obj.startEraseCb, slcName});
            
            %second, display roi boundaries
            % clear image axes 1
            axes(obj.hdlAxes(1));
            h = imagesc(obj.correctImage(slcSerie(:, :, obj.slcPos)));
            set(h, 'ButtonDownFcn', {@obj.onImgClick, slcName});
            obj.plotSearchMaskBounds(slcName);
            %get label Image
            lblImg = obj.labelImgMap(slcName);
            nbRois = max(lblImg(:));
            
            h = figure;
            cmap = colormap(jet(nbRois));
            close(h);
            for k = 1 : nbRois
                curRoi = lblImg;
                curRoi(curRoi ~= k) = 0;
                %lblImg = lblImg + (k * );
                [B, ~] = bwboundaries(imdilate(curRoi, strel('disk', 1)));
                axes(obj.hdlAxes(2)); hold on;
                for l = 1 : length(B)
                    boundary = B{l};
                    if size(boundary, 1) > 2
                        obj.optimFocus(slcName, obj.hdlAxes(1));
                        obj.smoothPlot(boundary, cmap(k, :), 2);
                        obj.optimFocus(slcName, obj.hdlAxes(2));
                        obj.smoothPlot(boundary, cmap(k, :), 2);
                    end
                end
            end
            
        end%plotRoiBoundaries
        
        function dispHistograms(obj, slcName)
            try
                switch obj.getParametricMapName()
                    case 'none'
                        tmpImSerie = obj.slcSerieMap(slcName);
                        parametricMap = zeros(size(tmpImSerie(:,:,1)));
                        figureMgr.getInstance().closeFig('histograms');
                        return;
                    otherwise
                        parametricMap = loadmat(fullfile(obj.patientPath, 'deconvolution', obj.getMethodName(), slcName, [obj.getParametricMapName() '.mat']));
                end
            catch
                
                cprintf('orange', 'SegmentationToolManualMultiRoiMapDisplay:dispHistograms: could not load paramteric map %s(%s) for slice %s', obj.getParametricMapName(), obj.getMethodName(), slcName);
                return;
            end
            xbins = 0 : 0.2 : max(parametricMap(:));
            figureMgr.getInstance().newFig('histograms'); cla; hold on;
            hist(gca, parametricMap(parametricMap ~= 0), xbins);
            mainHistHdle = get(gca, 'children');
            xlim([-0.1 max(parametricMap(:))]);
            
            lblMaskNameKS = fields(obj.lblNameStruct);
            lblImage = obj.labelImgMap(slcName);
            nbRois = max(lblImage(:));
            for k = 1 : nbRois
                maskParametricMap = lblImage;
                maskParametricMap(maskParametricMap ~= k) = 0;
                maskParametricMap = maskParametricMap ./ k;
                maskParametricMap = maskParametricMap .* parametricMap;
                hist(gca, maskParametricMap(maskParametricMap ~= 0), xbins);
            end
            
            cmap = colormap(jet(nbRois));
            h = get(gca, 'children');
            for k = 1 : nbRois + 1
                if h(k) == mainHistHdle;
                    set (h(k), 'facecolor', ones(1, 3) .* 0.95);
                else
                    set (h(k), 'facecolor', cmap((nbRois + 1) - k, :));
                    %set (h(k), 'facealpha', 0.7);
                end
            end
            
        end%dispHistograms
        
        function plotRegionTimeCurves(obj, slcName)
            slcSerie = obj.slcSerieMap(slcName);
            figureMgr.getInstance().newFig('curves'); cla; hold on;
            lblMaskNameKS =  fields(obj.lblNameStruct);
            lblImage = obj.labelImgMap(slcName);
            nbRois = max(lblImage(:));
            cmap = colormap(jet(nbRois));
            for k = 1 : length(lblMaskNameKS)
                [xPos, yPos] = ind2sub(size(lblImage), find(lblImage == k));
                tmp = 0;
                for l = 1 : length(xPos)
                    tmp = tmp + squeeze(slcSerie(xPos(l), yPos(l), :));
                end
                avgCtc = tmp ./ length(xPos);
                plot(avgCtc, 'color', cmap(k, :));
            end
            legend(lblMaskNameKS);
        end%plotRegionTimeCurves
        
        function updateRoisInfo(obj, slcName)
            roisMask = obj.labelImgMap(slcName);
            
            roiInfo.id = obj.lblNameStruct.(obj.getRoiName);
            roiInfo.name = obj.getRoiName();
            roiInfo.surface = numel(roisMask(roisMask == obj.lblNameStruct.(obj.getRoiName())));
            try
                seedsMask = obj.seedsMaskMap(slcName);
                [x, y] = ind2sub(size(seedsMask), find(seedsMask == roiInfo.id));
                roiInfo.seed.x = x;
                roiInfo.seed.y = y;
                roiInfo.thresh = obj.getThreshold();
            catch
                obj.lgr.info('no seed found for this mask');
            end
            
            %add roiInfo to roiInfoCell
            % is it empty?
            if isempty(obj.roiInfoCell)
                %yes just add it
                obj.roiInfoCell{1} = roiInfo;
            else
                % is it a new region?
                for k = 1 : length(obj.roiInfoCell)
                    if strcmp(obj.roiInfoCell{k}.name, roiInfo.name)
                        % no -> update it
                        obj.roiInfoCell{k} = roiInfo;
                        return;
                    end
                end%for
                %yes add it
                obj.roiInfoCell{length(obj.roiInfoCell) + 1} = roiInfo;
            end
        end%updateRoisInfo
        
        function dumpRoisInfo(obj, slcName)
            roisMask = obj.labelImgMap(slcName);
            roiNameList = fields(obj.lblNameStruct);
            
            cprintf('DGreen', '============\nroi summary:\nslice: %s\n ', slcName);
            for k = 1 : length(roiNameList)
                roiName = char(roiNameList(k));
                roiLabel = obj.lblNameStruct.(roiName);
                roiSurf = numel(roisMask(roisMask == roiLabel));
                cprintf('DGreen', '\t roi: %s, label: %d, surface: %d\n ', roiName, roiLabel, roiSurf);
            end
            cprintf('DGreen', '============\n');
        end%dumpRoisInfo
        
        function startEraseCb(obj, ~, ~, slcName)            
            mask = obj.labelImgMap(slcName);
            slcSerie = obj.slcSerieMap(slcName);
            axes(obj.hdlAxes(2)); 
            imagesc(overlay(obj.correctImage(slcSerie(:, :, obj.slcPos)), mask));
            axis off image;
            mask = obj.maskMap(slcName);
            rect = obj.optimFocus(slcName, obj.hdlAxes(2));
            
            set(gcf, 'WindowButtonMotionFcn', {@obj.eraseCb, slcName});
            set(gcf,'Pointer', 'circle');
        end%startEraseCb
        
        function eraseCb(obj, ~, ~, slcName)
            mask = obj.labelImgMap(slcName);
            slcSerie = obj.slcSerieMap(slcName);
            coordinates = get(gca, 'CurrentPoint');
            coordinates = floor(coordinates(1, 1:2));
            if ~coordinates(1); coordinates(1) = 1; end
            if ~coordinates(2); coordinates(2) = 1; end
            [H, W, ~] = size(slcSerie);
            if (coordinates(1) < 0) || (coordinates(2) < 0) ||...
                (coordinates(1) > H) || (coordinates(2) > W)
%                 cprintf('orange', 'SegmentationToolManualMultiRoiMapDisplay::eraseCb: out of range coordinates');
%                 cprintf('orange', 'coordinates(1): %d\ncoordinates(2): %d \n rect(3): %d\n rect(4): %d\n', coordinates(1), coordinates(2), rect(3), rect(4));
                return% out of image
            end
            mask(coordinates(2) - 1, coordinates(1)) = 0;
            mask(coordinates(2), coordinates(1) - 1) = 0;
            mask(coordinates(2) - 1, coordinates(1) - 1) = 0;
            mask(coordinates(2) - 1, coordinates(1) + 1) = 0;
            mask(coordinates(2), coordinates(1)) = 0;
            mask(coordinates(2) + 1, coordinates(1) - 1) = 0;
            mask(coordinates(2) + 1, coordinates(1)) = 0;
            mask(coordinates(2), coordinates(1) + 1) = 0;
            mask(coordinates(2) + 1, coordinates(1) + 1) = 0;
            axes(obj.hdlAxes(2));
            imagesc(overlay(obj.correctImage(slcSerie(:, :, obj.slcPos)), mask));

            obj.labelImgMap(slcName) = mask;
            set(gcf, 'WindowButtonUpFcn',{@obj.stopEraseCb, slcName});
        end%erase
        
        function stopEraseCb(obj, ~, ~, slcName)
            set(gcf, 'WindowButtonMotionFcn', '');
            set(gcf, 'WindowButtonUpFcn', '');
            set(gcf,'Pointer', 'arrow');
            obj.plotRoiBoundaries(slcName);
            try
                obj.dispHistograms(slcName);
            catch 
                obj.lgr.err('error trying to display histograms');
            end
            obj.plotRegionTimeCurves(slcName);
            obj.updateRoisInfo(slcName);
            obj.dumpRoisInfo(slcName);
        end%stopErase
        
        function closeFigCb(obj, ~, ~, slcName)
            fm = figureMgr.getInstance();
            
            switch questdlg('keep work for save?')
                case 'Yes'
                    obj.saveWork(slcName);
                case 'No'
                otherwise
                    return;
            end
            fm.closeFig('histograms');
            fm.closeFig('curves');
            fm.closeFig(slcName);
            
        end%closeFigCb
        
        function saveWork(obj, slcName)
            obj.BoundsOverlayImgMap = mapInsert(obj.BoundsOverlayImgMap, slcName, frame2im(getframe(obj.hdlAxes(1))));
            key = [slcName '_' obj.getMethodName()];
            obj.paramerticMapOverlayImgMap = mapInsert(obj.paramerticMapOverlayImgMap, key, frame2im(getframe(obj.hdlAxes(2))));
            if (figureMgr.getInstance.focus('histograms')  > 0)
                obj.HistogramImgMap = mapInsert(obj.HistogramImgMap, key, frame2im(getframe(gca)));
            else
                cprintf('orange', 'this figure does not exist\n');
            end
            if(figureMgr.getInstance.focus('curves') > 0)
                obj.timeCurvePlotImgMap = mapInsert(obj.timeCurvePlotImgMap, key, frame2im(getframe(gca)));
            else
                cprintf('orange', 'this figure does not exist\n');
            end
        end%saveWork
        
        function onParametricMapChanged(obj, ~, ~, slcName)
            obj.plotRoiBoundaries(slcName)
            obj.dispHistograms(slcName);
        end%onParametricMapChanged
        
        function onKeyPressCb(obj, ~, arg, slcName)
            switch arg.Key
                case 'uparrow'
                    if obj.histOpt.brightness < 100
                        obj.histOpt.brightness = obj.histOpt.brightness + 1;
                    end
                case 'downarrow'
                    if obj.histOpt.brightness > 0
                        obj.histOpt.brightness = obj.histOpt.brightness - 1;
                    end
                case 'leftarrow'
                    if obj.histOpt.contrast > 0.2
                        obj.histOpt.contrast = obj.histOpt.contrast - 0.2;
                    end
                case 'rightarrow'
                    if obj.histOpt.contrast < 2.4
                        obj.histOpt.contrast = obj.histOpt.contrast + 0.2;
                    end
                case 'a'
                    obj.addRoi([],[], slcName);
                    return;
                case 'n'
                    set(obj.CtrlUI.roiNameUI, 'string', 'normal');
                    obj.addRoi([],[], slcName);
                    return;
                case 'l'
                    set(obj.CtrlUI.roiNameUI, 'string', 'lesion');
                    obj.addRoi([],[], slcName);
                    return;
            end%switch
            axes(obj.hdlAxes(1));
            slcSerie = obj.slcSerieMap(slcName);
            h = imagesc(obj.correctImage(slcSerie(:, :, obj.slcPos))); axis off; axis image;
            set(h, 'ButtonDownFcn', {@obj.startEraseCb, slcName});
            colormap gray;
            obj.dispSlicePos(obj.slcPos, size(slcSerie, 3));
            obj.optimFocus(slcName);
            obj.plotSearchMaskBounds(slcName);
        end%onKeyPressCb
        
        function definitionTypeCb(obj, arg1, ~, ~)
            switch arg1
                case obj.CtrlUI.roiTypeRb(1)
                    set(obj.CtrlUI.roiTypeRb(1), 'Value', 1);
                    set(obj.CtrlUI.roiTypeRb(2), 'Value', 0);
                    set(obj.CtrlUI.threshUI, 'enable', 'off');
                case obj.CtrlUI.roiTypeRb(2)
                    set(obj.CtrlUI.roiTypeRb(1), 'Value', 0);
                    set(obj.CtrlUI.roiTypeRb(2), 'Value', 1);
                    set(obj.CtrlUI.threshUI, 'enable', 'on');
            end
        end%definitionTypeCb
        
    end%(Access = protected)
end

