classdef pdScanRegistrationTool < toolBase
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        pdScanImg;
        corrPdScanImg;
        mask;
    end
    
    methods (Access = public)
        function obj = prepare(obj, opt)
            obj.pdScanImg = opt.pdScanImg;
            obj.mask = opt.mask;
        end% prepare
        
        function obj = run(obj)
            obj.corrPdScanImg = obj.pdScanImg;
            hdle = figureMgr.getInstance().newFig('pdScanRegistrationTool_UI');
            obj.refreshDisplay();
            waitfor(hdle);
        end%run(obj)
        
        
        %% getters
        function corrPdScanImg = getCorrPdScanImg(obj)
            corrPdScanImg = obj.corrPdScanImg;
        end%getCorrPdScanImg
    end%methods (Access = public)
    
    methods (Access = protected)
        
        
        function obj = onKeyPressCb(obj, ~, arg)
            switch arg.Key
                case 'uparrow'
                     obj = obj.shiftImage(0, 1);
                case 'downarrow'
                     obj = obj.shiftImage(0, -1);
                case 'leftarrow'
                    obj = obj.shiftImage(1, 0);
                case 'rightarrow'
                    obj = obj.shiftImage(-1, 0);
                case 'r'
                    obj.corrPdScanImg = obj.pdScanImg;
                case 'return'
                    figureMgr.getInstance().closeFig('pdScanRegistrationTool_UI');
                    return;
            end%switch
            obj.refreshDisplay();
        end%onKeyPressCb
        
        function obj = refreshDisplay(obj)
            figureMgr.getInstance().newFig('pdScanRegistrationTool_UI');
            imagesc(obj.corrPdScanImg); axis off image;
            obj.plotBoundaries()
            obj.optimFocus();
            set(gcf, 'KeyPressFcn', @obj.onKeyPressCb);
        end%refreshDisplay
        
        function plotBoundaries(obj)
            %first plot mask bounds
            [B, ~] = bwboundaries(imdilate(obj.mask, strel('disk', 1)));
            hold on;
            for l = 1 : length(B)
                boundary = B{l};
                if l == 1
                    obj.smoothPlot(boundary, [0 1 0]);
                else
                    obj.smoothPlot(boundary, [1 0 0]);
                end
            end
        end%plotBoundaries
        
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
        
        function obj = shiftImage(obj, horzShiftVal, vertShiftVal)
            [H, W] = size(obj.corrPdScanImg);
            tmp = zeros(H, W);
            for k = 1 : H
                for l = 1 : W
                    try
                        tmp(k, l) = obj.corrPdScanImg(k + vertShiftVal, l + horzShiftVal);
                    catch
                        tmp(k, l) = 0;
                    end
                end
            end
            obj.corrPdScanImg = tmp;
        end%shiftImage
        
        function optimFocus(obj)
            margin = 10;
            box = regionprops(logical(obj.mask), 'Area', 'BoundingBox');
            rect = box.BoundingBox;
            set(gca, 'xlim', [rect(1) - margin , (rect(1) + rect(3) + margin)], 'ylim', [rect(2) - margin, (rect(2) + rect(4) + margin)]);
        end%optimFocus
    end%methods (Access = protected)
    
end

