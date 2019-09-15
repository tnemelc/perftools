classdef myo2stripUI < imSeriesUI  & maskOverlayBaseUI
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stripTool;
        resultsSubPanelsTab;
        handleAxesTabPnl2;
        tgroup;
    end
    
    %% public static method
    methods (Static)
        function obj = getInstance()
            persistent localObj;
            %which isvalid
            if isempty(localObj) %|| ~isvalid(localObj)
                localObj = myo2stripUI;
            end
            obj = localObj;
        end
    end%methods (Static)
    
    
    methods (Access = public)
        
        function obj = initialize(obj, hParent, pluginInfo, opt)
            obj.initialize@imSeriesUI(hParent, pluginInfo, opt);
            obj = obj.initDataPathUI(fullfile(obj.basePath, 'patientData', 'patientName', 'example'));
        end
    end% methods (Access = public
    
    methods (Access = protected)
        function goCb(obj, ~, ~)
            clc
            obj.wipeResults();
            obj.tgroup = [];
            
            obj.setFooterStr('starting run');
            try
                obj.stripTool = myo2stripTool();
                opt.dataPath = obj.getDataPath();
                obj.stripTool = obj.stripTool.prepare(opt);
                obj.stripTool = obj.stripTool.run();
            catch e
                obj.setFooterStr('something bad happened x_x');
                rethrow(e);
            end
            obj.setFooterStr('run completed successfully');
            obj.dispResults();
        end%goCb(obj)
        %%
        function saveCb(obj)
        end%saveCb(obj)
        
        function prepareResultsDisplay(obj)
            obj.tgroup = uitabgroup('Parent', obj.rPanel);
            obj.resultsSubPanelsTab(1) = uitab('Parent', obj.tgroup, 'Title', 'View1');
            obj.resultsSubPanelsTab(2) = uitab('Parent', obj.tgroup, 'Title', 'View2');
        end
        
        %%
        function dispResults(obj)
            if isempty(obj.tgroup)
                obj.prepareResultsDisplay();
            end 
            if isempty(obj.handleAxesTab)
                obj.handleAxesTab = tight_subplot(3, 3, [.05 .05], [.05 .05], [.1 .01], obj.resultsSubPanelsTab(1));
                obj.handleAxesTabPnl2 = tight_subplot(3, 1, [.05 .05], [.05 .05], [.1 .01], obj.resultsSubPanelsTab(2));
            end
            isKS = obj.stripTool.getSeriesKS(); %im series names
            for k = 1 : length(isKS)
                isName = char(isKS(k));
                
                imSerie = obj.stripTool.getImserie(isName);
                obj.displayImSerie(imSerie,...
                                    obj.handleAxesTab((k - 1) * 3 + 1), isName);
                stripSerie = obj.stripTool.getStripSerie(isName);
                obj.displayStrip(stripSerie(:, :, obj.slcTimePos),...
                                    obj.handleAxesTab(k * 3 - 1));
                
                stripLineSerie = obj.stripTool.getStripLineSerie(isName);
                obj.displayStripLine(stripLineSerie(:, obj.slcTimePos), obj.handleAxesTab(k * 3));
                obj.displayStripLineSerie(stripLineSerie, obj.handleAxesTabPnl2(k), isName);
            end
            obj.displayLandmarks();
            obj.displayMyoBoundaries();
            set(gcf, 'WindowScrollWheelFcn', {@obj.onScrollCb, size(imSerie, 3)});
        end%dispResults
        %%
        function displayImSerie(obj, imSerie, axHdle, isName)
            axes(axHdle);
            imagesc(obj.correctImage(imSerie(:, :, obj.slcTimePos)));
            colormap gray; axis off image;
            text('units', 'normalized', 'position', [0.5, 0.05], 'fontsize', 10,...
                'color', 'white', 'string', ...
                sprintf('%s, %d/%d', isName, obj.slcTimePos, size(imSerie, 3)));
            obj.optimizeFocus(axHdle, obj.stripTool.getMyoMask(isName));
        end%displayImSerie
        %%
        function displayStrip(obj, strip, axHdle)
            axes(axHdle);
            imagesc(obj.correctImage(strip));
        end%diplayStrip
        %%
        function displayStripLine(obj, stripLine, axHdle)
            axes(axHdle);
            plot(stripLine, '*');
        end%displayStripLine
        
        function displayStripLineSerie(obj, stripLineSerie, axHdle, isName)
            axes(axHdle);
            imagesc(stripLineSerie); axis off;
            colormap gray;
            title(isName);
        end
        %%
        function displayLandmarks(obj)
            h = figure;
            cmap = colormap(jet(4)); close(h);
            isKS = obj.stripTool.getSeriesKS();
            for k = 1 : length(isKS)
                isName = char(isKS(k));
                center = obj.stripTool.getMyoCentroid(isName);
                
                axes(obj.handleAxesTab((k - 1) * 3 + 1)); hold on;
                plot([center(1) center(1)], [center(2) center(2) + 5], 'color', cmap(1, :));
                plot([center(1) center(1) + 5], [center(2) center(2)], 'color', cmap(2, :));
                plot([center(1) center(1)], [center(2) center(2) - 5], 'color', cmap(3, :));
                plot([center(1) center(1) - 5], [center(2) center(2)], 'color', cmap(4, :));
                
                axes(obj.handleAxesTab(k * 3 - 1)); hold on;
                plot([1 100], [1     1], 'color', cmap(1, :));
                plot([1 100], [90   90], 'color', cmap(2, :));
                plot([1 100], [180 180], 'color', cmap(3, :));
                plot([1 100], [270 270], 'color', cmap(4, :));
                plot([1 100], [360 360], 'color', cmap(1, :));
            end
        end%displayLandMarks
        %%
        function displayMyoBoundaries(obj)
            isKS = obj.stripTool.getSeriesKS();
            for k = 1 : length(isKS)
                isName = char(isKS(k));
                bnds = obj.processMaskBounds(obj.stripTool.getMyoMask(isName));
                obj.boundariesPlot(bnds{1}, [1 0 0], obj.handleAxesTab((k - 1) * 3 + 1), 2);
                obj.boundariesPlot(bnds{2}, [0 1 0], obj.handleAxesTab((k - 1) * 3 + 1), 2);
            end
        end%displayMyoBoundaries
        
        %%
        function onScrollCb(obj, ~, arg2, maxPosValue)
            obj.onScrollCb@imSeriesUI([], arg2, maxPosValue);
            obj.dispResults();
        end
    end%methods (Access = protected)
    
end%classdef myo2StripUI 

