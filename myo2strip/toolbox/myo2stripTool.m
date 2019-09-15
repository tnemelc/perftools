classdef myo2stripTool < baseImgSerieTool 
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        myoMaskMap;
        stripImSeriesMap;
        stripLineSeriesMap;
        myoCentroidMap;
    end
    
    methods (Access = public)
        %%
        function obj = prepare(obj, opt)
            obj = obj.prepare@baseImgSerieTool(opt);
            obj = obj.loadMyoMask();
        end%prepare
        %%
        function obj = run(obj, ~)
            obj = obj.run@baseImgSerieTool();
            obj = obj.processMyo2StripImSeries();
            obj = obj.processStripLineSeries();
        end
        
        %% getters
        %%
        function stripSerie = getStripSerie(obj, serieName)
            stripSerie = obj.stripImSeriesMap(serieName);
        end
        %%
        function stripLineSerie = getStripLineSerie(obj, serieName)
            stripLineSerie = obj.stripLineSeriesMap(serieName);
        end%getStripLineSerie
        %%
        function myoCentroid = getMyoCentroid(obj, serieName)
            myoCentroid = obj.myoCentroidMap(serieName);
        end
        %%
        function myoMask = getMyoMask(obj, serieName)
            myoMask = obj.myoMaskMap(serieName);
        end
    end%methods (Access = public)
    
    methods (Access = protected)
        %%
        function obj = loadMyoMask(obj)
            for k = 1 : length(obj.isKS)
                imSerieName = char(obj.isKS(k));
                myoMask = loadmat(fullfile(obj.dataPath, 'dataPrep', imSerieName, 'mask.mat'));
                obj.myoMaskMap = mapInsert(obj.myoMaskMap, imSerieName, myoMask);
            end%
        end%loadMyoMask(obj
        %%
        function obj = processMyo2StripImSeries(obj)
            for k = 1 : length(obj.isKS)
                imSerieName = char(obj.isKS(k));
                
                obj.stripImSeriesMap = mapInsert(obj.stripImSeriesMap, imSerieName, ...
                                    obj.processMyoStrip(imSerieName));
            end
        end
        
        %%
        function stripSerie = processMyoStrip(obj, imSerieName)
            imSerie = obj.imSerieMap(imSerieName);
            myoMask = obj.myoMaskMap(imSerieName);
            center = regionprops(myoMask, 'centroid');
            center = floor(center.Centroid);
            obj.myoCentroidMap = mapInsert(obj.myoCentroidMap, imSerieName, center);
            [W, H, T] = size(imSerie);
            %     processTheta(H, W/2, H/2, W/2) %=0
            %     processTheta(H/2, W, H/2, W/2) %=90
            %     processTheta(0, W/2, H/2, W/2) %=180
            %     processTheta(H/2, 0, H/2, W/2) %=270
            for k = 1 : T
                strip = zeros(360, W);
                imSerie(center(2), center(1), k) = 0;
                for m = 1 : W
                    for n = 1 : H
                        if myoMask(m, n)
                            try
                                rho = round(sqrt((m - center(2))^2 + (n - center(1))^2 )) + 50;
                                theta = round(obj.processTheta(m, n, center(2), center(1)));
                                strip(theta, rho) = imSerie(m, n, k);
                            catch e
                                obj.lgr.err('error processing strip');
                                rethrow(e);
%                                 throw(MException('myo2stripTool:processMyoStrip', 'error processing strip'));
                            end
                        end
                    end
                end
                stripSerie(:, :, k) = strip;
            end
        end%processMyoStrip
        
        %%
        function obj = processStripLineSeries(obj)
            for k = 1 : length(obj.isKS)
                imSerieName = char(obj.isKS(k));
                obj.stripLineSeriesMap = mapInsert(obj.stripLineSeriesMap, ...
                    imSerieName, obj.processStripLineSerie(imSerieName));
            end
        end%processStripLineSeries
        
        %% 
        function stripLineSerie = processStripLineSerie(obj, stripSerieName)
            stripSerie = obj.stripImSeriesMap(stripSerieName);
            
            for k = 1 : size(stripSerie, 3)
                strip = stripSerie(:, :, k);
                stripLine = nan(1, 360);
                for m = 1 : 360
                    tmp = strip(m, :);
                    tmp = tmp(tmp > 0);
                    if isempty(tmp)
                        stripLine(m) = 0;
                    else
                        stripLine(m) = mean(tmp);
                    end
                end
                stripLineSerie(:, k) = stripLine; 
            end
            
        end%stripLineSerie
        
        %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % theta = 0 => |
        %              v
        %
        %theta = 90 => ->
        %theta = 180=> Î
        %theta = 270 => <-
        %
        %                  H
        %   0------------------>x
        %   |              |
        %   |              |
        %   |              |
        % W |---------------
        %   |
        % y V
        
        function theta = processTheta(obj, x, y, x0, y0)
            theta = atan2d(y - y0, x - x0);
            
            if 0 >= theta
                theta = 360 + theta;
            end
        end

        
        
    end%methods (Access = protected)
end

