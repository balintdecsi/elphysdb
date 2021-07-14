function propagated = datasumPropagation(DATASUMSAMPLE)

datasumFields = fieldnames(DATASUMSAMPLE);
datasumCell = struct2cell(DATASUMSAMPLE);
firstTime = hms2realtime(12, 25, 18);
lastTime = hms2realtime(18, 23, 55);
elapsedTime = lastTime - firstTime;
for k = 1:50
    x = rand;
    IVtime = firstTime + k * 0.02 * elapsedTime;
    for i = 1:size(datasumCell, 1)
        if i == 1
            if isnumeric(datasumCell{i,:,end})
                random = x * (datasumCell{i,:,end} / 5) + (0.9 * datasumCell{i,:,end});
                datasumCell{i,:,end + 1} = random;
            else
                datasumCell{i,:,end + 1} = NaN;
            end
        elseif i == 204
            datasumCell{i,:,end} = '1811211ap-generated.mat_g1_s10_c3';
        elseif i == 207
            datasumCell{i,:,end} = IVtime;
        elseif i == 208
            datasumCell{i,:,end} = firstTime;
        else
            if isnumeric(datasumCell{i,:,end - 1})
                random = x * (datasumCell{i,:,end - 1} / 5) + (0.9 * datasumCell{i,:,end - 1});
                datasumCell{i,:,end} = random;
            else
                datasumCell{i,:,end} = NaN;
            end
        end
    end
end

propagated = cell2struct(datasumCell, datasumFields, 1);

end