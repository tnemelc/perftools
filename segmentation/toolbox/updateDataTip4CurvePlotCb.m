function output_txt = updateDataTip4CurvePlotCb(obj, event_obj, pixCurve, filtCurve, avgCurve)
% Display the position of the data cursor
% obj          Currently not used (empty)
% event_obj    Handle to event object
% output_txt   Data cursor text string (string or cell array of strings).

% gcaPos = find(axesTab == gca);
pos = get(event_obj, 'Position');

t = pos(1);

stdCtc = std(pixCurve(4:t));
stdAvgCtc = std(avgCurve(4:t));

try
    stdFiltCtc = std(filtCurve(4:t));
catch
    stdFiltCtc = nan;
end

output_txt = {['X: ',num2str(pos(1),4)],...
    ['Y: ', num2str(pos(2),4)],...
    ['std raw  ctc: ', num2str(stdCtc)],...
    ['std filt ctc: ', num2str(stdFiltCtc)], ...
    ['std avg  ctc: ', num2str(stdAvgCtc)]};

end%updateDataTipCb