% manualMultiRoiSegmentation.m
% brief: 
%
%
% references:
%
%
% input:
% arg1: ...
% arg2: ... 
% output:
%
% arg3: ...
% arg4: ...
%
%
% keywords:
% author: C.Daviller
% date: 08-Dec-2017  


 function [regionMaskStack, regionNameList] = manualMultiRoiSegmentation(slcSerie, lgeImg, searchMask, serieName)
 
    [H, W, nbImages] = size(slcSerie);
    slcPos = 20;
    nbRegions = 0;
    
    imgOpt.brightness = 0;
    imgOpt.contrast = 1;
    imgOpt.angle = 0;
    focusedRoi = 'none';
    regionNameList = [];
    fm = figureMgr.getInstance();
    figHdle = fm.newFig(serieName); fm.resize(serieName, 2, 2);
    subplot(1, 2, 1); colormap gray;
    ha = tight_subplot(1, 3, [.1 .03], [.15 .01], [.01 .01]);
    axes(ha(1));
    imgHdle = imagesc(correctImage(slcSerie(:, :, slcPos))); axis off; axis image;
    dispSlicePos();
    optimFocus(searchMask);
    %display lge image
    axes(ha(2));
    imgHdle = imagesc(lgeImg); 
    axis off; axis image; colormap gray;
    
    set(imgHdle,'ButtonDownFcn', @createRoiCb);
    set(figHdle,'WindowScrollWheelFcn', @OnScrollCb);
    set(figHdle, 'KeyPressFcn', @onKeyPressCb);
    
    %add button
    uicontrol('Style', 'pushbutton',...
        'Units',  'normalized',...
        'Position', [0.15 0.1 0.1 0.05],...
        'String', 'add roi',...
        'Callback', {@addRoi, 'myo'}, ...
        'Visible', 'on');
    
    uicontrol('Style', 'text',...
        'Units',  'normalized',...
        'Position', [0.4 0.1 0.09 0.05],...
        'String', 'RoiName');
    
    roiNameUI= ...
        uicontrol('Style', 'edit',...
        'Units',  'normalized',...
        'String', 'normal',...
        'Position', [0.5 0.1 0.15 0.05]);
    
    % Create three radio buttons in the button group.
    % radio buttons
    rb(1) = uicontrol('Style', 'radiobutton', ...
    'Callback', @radioBnCb, ...
    'Units',    'normalized', ...
    'Position', [0.71 0.1 0.09 0.05], ...
    'String',   'manual', ...
    'Value',    1, ...
    'Enable', 'on');

   rb(2) = uicontrol('Style', 'radiobutton', ...
    'Callback', @radioBnCb, ...
    'Units',    'normalized', ...
    'Position', [0.71 0.05 0.09 0.05], ...
    'String',   'roi growing', ...
    'Value',    0, ...
    'Enable', 'on');

    uicontrol('Style', 'text',...
        'Units',  'normalized',...
        'Position', [0.85 0.05 0.05 0.05],...
        'String', 'threshold');
    
    threshUI = ...
        uicontrol('Style', 'edit',...
        'Units',  'normalized',...
        'String', '5',...
        'Position', [0.91 0.05 0.05 0.05],...
        'enable', 'off');
    
    %OK button
    uicontrol('Style', 'pushbutton',...
        'Units',  'normalized',...
        'Position', [0.15 0.05 0.1 0.05],...
        'String', 'OK',...
        'Callback', @closeFig);
    
%     %colormap button
%     cmBnHdle = uicontrol('Style', 'checkbox',...
%         'Units',  'normalized', 'Position', [0.25 0.05 0.2 0.1], ...
%         'String',   'colormap', 'Value',    0, 'Callback', @setColormap);
    
    waitfor(figHdle);
    
    
    %% Callback function
     function mask = addRoi(~,~, roiName)
         switch getRoiChoice()
             case 'Manual'
                 mask = addRoiManual();
             case 'roiGrowing'
                 mask = addRoiGrowing();
         end
         dispROIPreview(mask);
         switch questdlg(sprintf('save ROI %s?\n', getRoiName()));
             case 'Yes'
                 regionMaskStack(:, :, nbRegions + 1) = mask .* (nbRegions + 1);
                 regionNameList = mapInsert(regionNameList, (nbRegions + 1), getRoiName());
                 nbRegions = nbRegions + 1;
                 cprintf('green', 'roi %s added\n', getRoiName());
                 dispRoiStack();
             otherwise
                 cprintf('orange', 'roi creation cancelled\n');
         end
         axes(ha(1));
         imagesc(correctImage(slcSerie(:, :, slcPos)));
         colormap gray; axis off; axis image;
     end
 
     function mask = addRoiManual()
         img =  correctImage(slcSerie(:, :, slcPos));
         minVal = min(min(img));
         maxVal = max(max(img));
         img = (img + abs(minVal)) / maxVal - minVal;
         axes(ha(1));
         mask = roipoly(img);
     end%addRoiManual
 
     function mask = addRoiGrowing()
         [x,y] = ginput(1);
         mask = growRegion(floor([x, y]));
     end%addRoiGrowing
 
     function dispRoiStack()
         axes(ha(3));
         for k = 1 : size(regionMaskStack, 3)
             tmp(:, :, k) = regionMaskStack(:, :, k) .* k;
         end
         img =  correctImage(slcSerie(:, :, slcPos));
         axes(ha(3));
         imagesc(overlay(img, sum(tmp, 3))); axis off image;
     end%dispRectangles
 
     function dispROIPreview(mask)
         img =  correctImage(slcSerie(:, :, slcPos));
         axes(ha(1));
         imagesc(overlay(img, mask));axis off image;
     end%dispFocusedROIPreview
 
 
     function dispFocusedROI()
         axes(ha(1));
         imagesc(correctImage(slcSerie(:, :, slcPos))); axis off image;
         switch focusedRoi
             case 'myo'
                 rectangle('Position', rectMyo, 'EdgeColor', 'b');
             case 'vd'
                 rectangle('Position', rectVD, 'EdgeColor', 'g');
             case 'vg'
                 rectangle('Position', rectVG, 'EdgeColor', 'r');
         end
     end%dispOneRectangle
 
     function OnScrollCb(~, arg)
         slcPos = floor(slcPos + arg.VerticalScrollCount);
         if slcPos < 1
             slcPos = 1;
         end
         if slcPos > size(slcSerie, 3)
             slcPos = size(slcSerie, 3);
         end
         xlim = get(ha(1), 'XLim');
         ylim = get(ha(1), 'YLim');
         axes(ha(1));
         imagesc(correctImage(slcSerie(:, :, slcPos)));
         colormap gray; axis off; axis image;
         dispSlicePos();
         set(ha(1), 'XLim', xlim);
         set(ha(1), 'YLim', ylim);
         %title (get(editInputDcm, 'String'));
     end
 
     function onKeyPressCb(~, arg)
         switch arg.Key
             case 'uparrow'
                 imgOpt.brightness = imgOpt.brightness + 1;
             case 'downarrow'
                 imgOpt.brightness = imgOpt.brightness - 1;
             case 'leftarrow'
                 imgOpt.contrast = imgOpt.contrast - 0.2;
             case 'rightarrow'
                 imgOpt.contrast = imgOpt.contrast + 0.2;
             case 'pageup'
                 imgOpt.angle = imgOpt.angle + 1;
             case 'pagedown'
                 imgOpt.angle = imgOpt.angle - 1;
             case 'return'
                 dispRectangles();
         end%switch
         axes(ha(1));
         imagesc(correctImage(slcSerie(:, :, slcPos))); axis off; axis image;
         dispSlicePos();
     end%onKeyPressCb
 
     function corrIm = correctImage(image)
         maxValue = max(image(:));
         lut(1, :) = (0 : maxValue);
         tmp = imgOpt.contrast .*  lut(1, :) + imgOpt.brightness;
         tmp(tmp < 0) = 0; tmp(tmp > maxValue) = maxValue;
         lut(2, :) = tmp;
         
         for k = 1 : numel(image)
             corrIm(k) = lut(2, lut(1,:) == floor(image(k)));
         end
         corrIm = reshape(corrIm, size(image));
         corrIm = imrotate(corrIm, imgOpt.angle);
     end%correctImage
 
     function optimFocus(mask)
         margin = 10;
         box = regionprops(logical(mask), 'Area', 'BoundingBox');
         rect = box.BoundingBox;
         set(gca, 'xlim', [rect(1) - margin , (rect(1) + rect(3) + margin)], 'ylim', [rect(2) - margin, (rect(2) + rect(4) + margin)]);
     end%optimFocus
 
     function closeFig(~, ~)
         close(figHdle);
     end%closeFig
 
     function dispSlicePos()
         txtPos = [0.85, 0.05];
         text('units','normalized','position', txtPos,'fontsize', 10, 'color', 'white', 'string', sprintf('%d/%d', slcPos, size(slcSerie, 3)))
     end%dispSlicePos
 
     function radioBnCb(arg1, arg2, arg3)
         switch arg1
             case rb(1)
                 set(rb(1), 'Value', 1);
                 set(rb(2), 'Value', 0);
                 set(threshUI, 'enable', 'off');
             case rb(2)
                 set(rb(1), 'Value', 0);
                 set(rb(2), 'Value', 1);
                 set(threshUI, 'enable', 'on');
         end
     end%radioBnCb
 
     function roiName = getRoiName()
         roiName = get(roiNameUI, 'String');
     end%getRoiId
 
     function roiChoiceStr = getRoiChoice()
         if get(rb(1), 'Value')
             roiChoiceStr = 'Manual';
         else
             roiChoiceStr = 'roiGrowing';
         end
     end%roiChoice
 
     function treshold = getThreshold()
         treshold = floor(str2num(get(threshUI, 'string')));
     end
 
     function mask = growRegion(seed)
         axes(ha(1)); hold all;
         plot(seed(1), seed(2), '*'); plot(seed(1), seed(2), 'o');
         delta = getThreshold();%floor(get(sldrUI, 'Value'));
         seedCtc = squeeze(correctImage(slcSerie(seed(2), seed(1), :)));
         
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
%          if get(fillHolesUI, 'Value')
%              mask = fillMaskHoles(mask, searchMask);
%          end
%          fm = figureMgr.getInstance();
%          cHdle = fm.getFig('extractMyo');
%          fm.focus('extractMyo');
%          axes(ha(2));
%          imHdle = imagesc(correctImage(slcSerie(:, :, slcPos)) + maskFactor .* mask);
%          axis off image;
%          axes(ha(1)); dispSlicePos();
%          axis off image;
%          set(imHdle, 'ButtonDownFcn', @startEraseCb);
%          set(cHdle, 'WindowButtonUpFcn', @stopEraseCb);
%          if ~dispFlag
%              return;
%          end
%          displayCurves(seedCtc, ubCtc, lbCtc);
         
     end%growRegionCb
end