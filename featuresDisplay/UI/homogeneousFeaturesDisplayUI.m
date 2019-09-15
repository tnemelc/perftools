classdef homogeneousFeaturesDisplayUI < featuresDisplayUI
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        plotStyle;
    end
    
    %% public static method
    methods (Static)
        function obj = getInstance()
            persistent localObj;
            %which isvalid
            if isempty(localObj) %|| ~isvalid(localObj)
                localObj = homogeneousFeaturesDisplayUI;
            end
            obj = localObj;
        end
    end%methods (Static)
    
    methods (Access = public)
        %%
        function obj = initialize(obj, hParent, pluginInfo, opt)
            obj = obj.initialize@featuresDisplayUI(hParent, pluginInfo, opt);
            obj.plotStyle = 'timeIntensityCurves';
            obj.initLateralBnPanel()
        end% initialize
        
        function initLateralBnPanel(obj)
            set(obj.buttonsPanelTab(4), 'callback', @obj.tooglePlotStyle);
        end%initLateralBnPanel
        
    end

    methods (Access = protected)
        %%
        function [x, y] = onImgClick(obj, arg1, arg2, slcName)
            switch obj.getFeatureType()
                case 'homogeneousFeaturesRois'
                    if strcmp('none', obj.maskEditMode)
                        [x, y] = obj.onImgClick@imSeriesUI(arg1, arg2, slcName);
                        if strcmp(obj.plotStyle, 'timeIntensityCurves')
                            obj.plotTic(x, y, slcName);
                        else %if strcmp(obj.plotStyle, 'featuresGradient')
                            obj.plotGradient(slcName, x, y);
                        end
                    else
                        [x, y] = onImgClick@featuresDisplayUI(obj, arg1, arg2, slcName);
                        obj.setFooterStr(sprintf('clicked on voxel(%d,%d) | slice %s', x, y, slcName));
                    end
                otherwise
                    [x, y] = onImgClick@featuresDisplayUI(obj, arg1, arg2, slcName);
                    obj.setFooterStr(sprintf('clicked on voxel(%d,%d) | slice %s', x, y, slcName));
            end
            
        end
        %% 
        function plotGradient(obj, slcName, x, y)
            roiId = obj.featTool.getRoiId(slcName, x, y);
            featGradientVect = obj.featTool.getNormFtGdtVect(slcName, roiId);
            axes(obj.handleAxesTab(4)); cla;
            plot(featGradientVect);
        end
        %%
        function plotTic(obj, x, y, slcName)
            lgdKS = {};
            %figureMgr.getInstance.newFig(sprintf('tic_%s', slcName)); clf;
            axes(obj.handleAxesTab(4)); cla;
            hold on;
            %user clicked tic
            slcSerie = obj.featTool.getSlcSerieMap(slcName);
            plot(squeeze(slcSerie(x, y, :)), 'color', ones(1, 3) * 0.25 ); lgdKS = [lgdKS 'clicked'];
            %seed tic
            roiMask = obj.featTool.getRoisMask(slcName);
            seedMask = obj.featTool.getSeedMask(slcName);
            roiID = roiMask(x, y);
            [xSeed, ySeed] = ind2sub(size(seedMask), find(seedMask == roiID, 1, 'first'));
            seedTic = squeeze(slcSerie(xSeed, ySeed, :));
            plot(seedTic, 'b'); lgdKS = [lgdKS 'seed'];
            roiMask(roiMask ~= roiMask(x, y)) = 0;
            roiMask(roiMask == roiMask(x, y)) = 1;
            [avgTic, minTic, maxTic] = obj.featTool.proccessRoiAvgTic(slcName, roiMask);
            plot(obj.featTool.proccessRoiAvgTic(slcName, roiMask), '-', 'color', [0 0.5 0]); lgdKS = [lgdKS 'roi avg TIC'];
            
            %min-max tic values
            fillPlot((1:length(minTic))', minTic', maxTic'); lgdKS = [lgdKS 'min/max values'];
            hl = legend(lgdKS);
            obj.setFooterStr(sprintf('clicked on voxel(%d,%d) | roi %d | slice %s', x, y, roiID, slcName));
            
            %axis tick
            set(obj.handleAxesTab(4), 'xtick', [0 length(avgTic)], 'xticklabel', [0 length(avgTic)]);
            set(obj.handleAxesTab(4), 'ytick', [0 round(max(maxTic))], 'yticklabel', [0 round(max(maxTic))]);
            set(obj.handleAxesTab(4), 'XMinorTick', 'on', 'YMinorTick', 'on')
            set(obj.handleAxesTab(4), 'XColor', [1 1 1]);
            set(obj.handleAxesTab(4), 'YColor', [1 1 1]);
            set(obj.handleAxesTab(4), 'color', [0 0 0]);
            
            % axis limits
            xlim([0, length(maxTic(:))]);
            ylim([0, max(maxTic(:)) + 5]);
            %legend
            set(hl, 'textColor', 'w');
            set(hl, 'fontsize', 8);
            set(hl, 'location', 'northwest');
        end
        %%
        function validKey = onKeyPressCb(obj, ~, arg)
            validKey = obj.onKeyPressCb@featuresDisplayUI([], arg);
            if validKey
                return;
            end
            validKey = true;
            switch arg.Key
                case 'c'
                    validKey = true;
                    obj.featTool.clearMyocardialBorders();
                    obj.displayMapOverlay();
                    obj.featTool.saveMyoMaskUpdate();
                    obj.setFooterStr('border cleared');
                case 'h'
                    cprintf('Dgreen', 'homogeneousFeaturesDisplayUI\n\tc: clear mask borders\n\te: mask erase\n');
                    validKey = false;
                otherwise
                    validKey = false;
            end
        end
        % 
        function saveCb(obj, ~, ~)
            obj.setFooterStr('start save');
            switch obj.getFeatureType();
                case 'homogeneousFeaturesRois'
                    isKS = obj.featTool.getSliceKS();
                    for k = 1 : length(isKS)
                        isName = char(isKS(k));
                        if ~isdir(fullfile(obj.getSavePath(), obj.getFeatureType(), isName))
                            mkdir(fullfile(obj.getSavePath(), obj.getFeatureType(), isName));
                        end
                        savemat(fullfile(obj.getSavePath(), obj.getFeatureType(), isName, 'roisMask.mat'), obj.featTool.getRoisMask(isName));
                    end
                otherwise
                    obj.saveCb@featuresDisplayUI();
            end
            obj.setFooterStr('save completed');
        end
        %%
        function tooglePlotStyle(obj, ~, ~)
            switch obj.plotStyle
                case 'timeIntensityCurves'
                    obj.plotStyle = 'featuresGradient';
                case 'featuresGradient'
                    obj.plotStyle = 'timeIntensityCurves';
            end
        end
    end
    
end

