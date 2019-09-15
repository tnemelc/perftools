%> @file imSeriesUI.m
%> @brief user interface base class
% =========================================================================
%> @brief base class GUI for perfusion image series This class let user to
%> display and navigate through image serie by mouse scrolling. It also
%> manages image click callbacks to display (for example) time curve
%> associated to voxel which the user clicked.
% =========================================================================

classdef imSeriesUI < baseUI
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %> frame number
        slcTimePos;
        %> cine display mode let user to watch the images as a movie.
        cineDisplayMode;
    end
    
    %%public methods
    methods (Access = public)
        %%
        function obj = initialize(obj, hParent, pluginInfo, opt)
            obj = obj.initialize@baseUI(hParent, pluginInfo, opt);
            obj.slcTimePos = 15;
            obj.cineDisplayMode = 'off';
            set(obj.buttonsPanelTab(7), 'cdata',...
                imread(fullfile(obj.basePath, 'ressources', 'icons', 'camera.tif')),...
                'callback', {@obj.switchCine},...
                'string', '', ...
                'TooltipString', 'run movie');
        end%initialize
    end
    
    methods (Access = protected)
        %%
        function onScrollCb(obj, ~, arg2, maxPosValue)
            obj.slcTimePos = floor(obj.slcTimePos  + arg2.VerticalScrollCount);
            if obj.slcTimePos < 1
                obj.slcTimePos = 1;
            end
            if obj.slcTimePos > maxPosValue
                obj.slcTimePos = maxPosValue;
            end
        end%onSCrollCb
        %%
        %> @brief returns position of clicked voxel and display it in the
        %> footer bar.
        function [x, y] = onImgClick(obj, arg1, arg2, slcName)
            axesHandle  = get(arg1, 'Parent');
            coordinates = get(axesHandle, 'CurrentPoint');
            coordinates = round(coordinates(1, 1:2));
            if ~coordinates(1); coordinates(1) = 1; end
            if ~coordinates(2); coordinates(2) = 1; end
            x = coordinates(2);
            y = coordinates(1);
            obj.setFooterStr(sprintf('clicked on voxel(%d,%d)', x, y));
        end%onImgClick
        %%
        function corrIm = correctImage(obj, image)
            corrIm = obj.correctImage@baseUI(image);
            bounds = imfilter(corrIm, fspecial('laplacian'));
            corrIm = (bounds + 10 * corrIm) / 11;
        end
        
        %% 
        function switchCine(obj, ~, ~)
            switch obj.cineDisplayMode 
                case 'off'
                    obj.cineDisplayMode = 'on';
                    obj.setFooterStr('cine on');
                    obj.runCine();
                case 'on'
                    obj.cineDisplayMode = 'off';
                    obj.setFooterStr('cine off');
            end
        end
        %%
        function runCine(obj)
            while strcmp('on', obj.cineDisplayMode)
                if obj.slcTimePos < 60
                    obj.slcTimePos = obj.slcTimePos + 1;
                else
                    obj.slcTimePos = 1;
                end
                obj.dispResults();
            end
        end%runCine(obj)
    end%methods (Access = protected)
    
end

