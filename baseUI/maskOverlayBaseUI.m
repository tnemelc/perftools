classdef maskOverlayBaseUI < baseUI
    %   abstract class derived from baseUI for mask overlay management
    %   Detailed explanation goes here
    
    properties
        maskEditMode;
        mask;
        boundsDisplayMode;
        
    end
    
    methods (Access = public)
        %%
        function obj = initialize(obj, hParent)
            obj.maskEditMode = 'none';
            obj.boundsDisplayMode = 'off';
        end%initialize
    end%methods (Access = public)
    
    methods (Access = protected)
        %%
        function obj = initLateralButtonsPanel(obj)
            obj = obj.initLateralButtonsPanel@baseUI();
            arg.Key = 'e';
            set(obj.buttonsPanelTab(1), 'cdata',...
                imread(fullfile(obj.basePath, 'ressources', 'icons', 'eraser.tif')),...
                'callback', {@obj.onKeyPressCb, arg},...
                'string', '', ...
                'TooltipString', 'erase mask');
            arg.Key = 'p';
            set(obj.buttonsPanelTab(2), 'cdata',...
                imread(fullfile(obj.basePath, 'ressources', 'icons', 'pencil.tif')),...
                'callback', {@obj.onKeyPressCb, arg},...
                'string', '', ...
                'TooltipString', 'edit mask');
            arg.Key = 'b';
            %edit myocardial boundaries
            set(obj.buttonsPanelTab(3), 'cdata',...
                imread(fullfile(obj.basePath, 'ressources', 'icons', 'bounds.tif')),...
                'callback', {@obj.onKeyPressCb, arg},...
                'string', '', ...
                'TooltipString', 'show/hide myocardium boundaries');
            set(obj.buttonsPanelTab(4), 'cdata',...
                imread(fullfile(obj.basePath, 'ressources', 'icons', 'brightness.tif')),...
                'callback', {@obj.setFooterStr, 'set brightness'},...
                'string', '', ...
                'TooltipString', 'set brightness');
            set(obj.buttonsPanelTab(5), 'cdata',...
                imread(fullfile(obj.basePath, 'ressources', 'icons', 'contrast.tif')),...
                'callback', {@obj.setFooterStr, 'set contrast'},...
                'string', '', ...
                'TooltipString', 'set contrast');
            %copy to clipboard
            set(obj.buttonsPanelTab(6), 'cdata',...
                imread(fullfile(obj.basePath, 'ressources', 'icons', 'screenCapture.tif')),...
                'callback', @obj.onCopy2Clipboard,...
                'string', '', ...
                'TooltipString', 'copy results to clipboard');
            
        end
        %%
        function optimizeFocus(obj, axes, mask)
            margin = 10;
            box = regionprops(logical(mask), 'Area', 'BoundingBox');
            rect = box.BoundingBox;
            set(axes, 'xlim', [rect(1) - margin , (rect(1) + rect(3) + margin)], 'ylim', [rect(2) - margin, (rect(2) + rect(4) + margin)]);
        end%optimizeFocus(obj, axes, mask)
        
        %%
        function B = processMaskBounds(obj, mask)
            [B, ~] = bwboundaries(mask);
            %sort bound by size....
            [~, I] = sort(cellfun(@length,B));
            B = B(I);
            B = flip(B);
            % and only keep the two largest
%             B = B(1:2);
        end% displayMyoMaskBounds
        
        %%
        function boundariesPlot(obj, boundaries, cmap, axesHdle, subSamplingFactor)
            if strcmp('off', obj.boundsDisplayMode)
                return;
            end
            axes(axesHdle);
            x = boundaries(:, 2);
            y = boundaries(:, 1);
            boundaryLength = length(x);
%             if numel(x) > 2
%                 subSamplingFactor = 2;
%             else
%                 subSamplingFactor = 1;
%             end
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
            hold on;
            plot(px, py, 'LineWidth', 2, 'color', cmap(1, :));
        end%boundariesPlot
        
         %% Callbacks
         %% 
         function validKey = onKeyPressCb(obj, ~, arg, arg2)
             if isfield(arg, 'Key')
                 validKey = obj.onKeyPressCb@baseUI([], arg);
             elseif isfield(arg2, 'Key');
                 validKey = obj.onKeyPressCb@baseUI([], arg2);
             else
                 throw(MException('maskOverlayBaseUI:onKeyPressCb', 'key is not specified'));
             end
             
             if validKey 
                 return;
             end
             validKey = true;
             switch arg.Key
                case 'e'
                    switchfigptr('eraser', gcf);
                    obj.maskEditMode = 'eraser';
                    obj.setFooterStr(sprintf('mask edit mode: %s', obj.maskEditMode));
                 case 'p'
                     switchfigptr('pencil', gcf);
                    obj.maskEditMode = 'pencil';
                    obj.setFooterStr(sprintf('mask edit mode: %s', obj.maskEditMode));
                 case 'b'
                     switch obj.boundsDisplayMode
                         case 'on'
                             obj.boundsDisplayMode = 'off';
                         case 'off'
                             obj.boundsDisplayMode = 'on';
                     end
                     obj.setFooterStr(sprintf('boundaries mode: %s', obj.boundsDisplayMode));
                 case 'h'
                     cprintf('Dgreen', 'maskOverlayUI\n\te: mask erase\n\tp: pencil\n\tb: bounds display/hide\n');
                     validKey = false;% set validkey false to run inherited functions
                     obj.setFooterStr('help displayed on console');
                 otherwise 
                     switchfigptr('default', gcf);
                     obj.maskEditMode = 'none';
                     validKey = false;
            end%switch
            
         end
         %%
         function onCopy2Clipboard(obj, ~, arg, arg2)
             try
                img = screencapture(obj.rPanel);
                h = figure('units','normalized','outerposition',[0 0 1 1]);
                tight_subplot(1,1, [0 0], [0 0],[0 0], h);
                imagesc(img); axis off image
                truesize;
                print(h, '-dmeta'); 
                close gcf;
                obj.setFooterStr('copied to clipboard');
             catch e
                 obj.setFooterStr('x_x sommething bad happened');
                 rethrow(e);
             end
         end
         %%
         function startMaskEditCb(obj, mask, opt)
             obj.mask = mask;
             switch obj.maskEditMode
                 case 'eraser'
                     obj.setFooterStr('mask erase mode activated');
                 case 'pencil'
                     obj.setFooterStr('mask pencil mode activated');
                 otherwise
                     switchfigptr('default', gcf);
                     return;
             end%switch
             
             set(gcf, 'WindowButtonMotionFcn', {@obj.maskEditCb, opt});
             set(gcf, 'WindowButtonUpFcn', {@obj.stopMaskEditCb, opt});
         end%startMaskEdit
         %%
         function [mask, x, y] = maskEditCb(obj, arg1, ~, opt)
             mask = nan;
             Neighboring = 4;
             coordinates = get(gca, 'CurrentPoint');
             coordinates = floor(coordinates(1, 1:2));
%              if ~coordinates(1); coordinates(1) = 1; end
%              if ~coordinates(2); coordinates(2) = 1; end
             x = coordinates(2) - 1;
             y = coordinates(1);
             [H, W] = size(obj.mask);
             if x < 1 || x > H || y < 1 || y > W
                 return;
             end
             switch obj.maskEditMode
                 case 'eraser'
                     maskFillVal = 0;
                     Neighboring = 8;
                 case 'pencil'
                     maskFillVal = 1;
                     Neighboring = 0;
                 otherwise
                     return;
             end
             
             obj.mask(x, y) = maskFillVal;
             if Neighboring > 0
                 obj.mask(x - 1, y) = maskFillVal;
                 obj.mask(x, y - 1) = maskFillVal;
                 obj.mask(x + 1, y) = maskFillVal;
                 obj.mask(x, y + 1) = maskFillVal;
             end
             if Neighboring > 4
                 obj.mask(x - 1, y - 1) = maskFillVal;
                 obj.mask(x - 1, y + 1) = maskFillVal;
                 obj.mask(x + 1, y - 1) = maskFillVal;
                 obj.mask(x + 1, y + 1) = maskFillVal;
             end
             mask = obj.mask;
         end%editCb
         %%
         function stopMaskEditCb(obj, ~, ~, opt)
             set(gcf, 'WindowButtonMotionFcn', '');
             %             switchfigptr('default', gcf);
             %obj.dispResults();
         end%stopEraseCb
        %% 
        function saveResultsFrames(obj, savePath, format)
            if nargin < 3
                format = 'png';
            end
            for k = 1 : length(obj.handleAxesTab)
                imwrite(frame2im(getframe(obj.handleAxesTab(k))), fullfile(savePath, sprintf('axes_%02d.%s', k, format)));
            end
        end
    end%methods (Access = protected)
    
end

