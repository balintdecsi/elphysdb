function result = mongoLogTest(logFpath, imageFolderpath, elphysStructpath)

%% error handling
if ~exist (logFpath, 'file')
    error('The specified logfile does not exist!');
end
if ~exist (imageFolderpath, 'dir')
    error('The specified image folder does not exist!');
end

%% templates & constants
cellProps = struct('id', [], 'date', [], 'phenotype', [], ...
    'elphys', struct('fpath', [], 'time', [], 'idx', []), ...
    'images', struct('fpath', [], 'stage', [], 'type', [], ...
    'boundingBox', struct('x', [], 'y', [], 'width', [], 'height', [])));
radius = 120;
lineExpression = '(?<date>\d{4}-\d{2}-\d{2}) (?<time>\d{2}:\d{2}:\d{2}),(?<msec>\d{3}) (?<tag>[A-Z]+) (?<msg1>.*) - (?<msg2>.*)';
imageExpression = 'Logging image with name: (?<name>.*)';
nameExpression = '.*(?<pcEvent>(starting|hunting|sealing))\.png';
% imageExpression = 'Logging image with name: (?<date>\d{4}-\d{2}-\d{2})_(?<time>\d{2}:\d{2}:\d{2}),(?<msec>\d{3})_(AP|VP)_(?<pcEvent>(starting|hunting|sealing))\.png';
% nameExpression = '(?<date>\d{4}-\d{2}-\d{2})_(?<time>\d{2}:\d{2}:\d{2}),(?<msec>\d{3})_(AP|VP)_(?<pcEvent>(starting|hunting|sealing))';

%% analyze diary file
i = 0;
j = 1;
fid = fopen(logFpath, 'r');
tline = fgetl(fid);
while ~isnumeric(tline) || tline ~= -1
    lineparts = regexp(tline, lineExpression, 'names');
    if ~isempty([lineparts.date]) && startsWith(lineparts.msg2, 'Logging image with name:')
        imageparts = regexp(lineparts.msg2, imageExpression, 'names');
        nameparts = regexp(imageparts.name, nameExpression, 'names');
        if nameparts.pcEvent == "starting"
            i = i + 1;
            j = 1;
            cellProps(i).id = i;
            Y = str2num(lineparts.date(1:4));
            M = str2num(lineparts.date(6:7));
            D = str2num(lineparts.date(9:10));
            H = str2num(lineparts.time(1:2));
            MI = str2num(lineparts.time(4:5));
            S = str2num(lineparts.time(7:8));
            cellProps(i).date = datetime(Y, M, D, H, MI, S);
            cellProps(i).phenotype = [];       
            cellProps(i).elphys.fpath = [];
            cellProps(i).elphys.time = [];
            cellProps(i).elphys.idx = [];
        end
        filename = fullfile(imageFolderpath, imageparts.name);
        if exist (filename, 'file')
            cellProps(i).images(j).fpath = filename;
            info = imfinfo(filename);
            cellProps(i).images(j).boundingBox.x = (([info.Width] / 2) - (radius / 2));
            cellProps(i).images(j).boundingBox.y = (([info.Height] / 2) - (radius / 2));
            cellProps(i).images(j).boundingBox.width = radius;
            cellProps(i).images(j).boundingBox.height = radius;
        else
            cellProps(i).images(j).fpath = 'Image missing';
            cellProps(i).images(j).boundingBox.x = ['default: ', num2str((1388 / 2) - (radius / 2))];
            cellProps(i).images(j).boundingBox.y = ['default: ', num2str((1040 / 2) - (radius / 2))];
            cellProps(i).images(j).boundingBox.width = radius;
            cellProps(i).images(j).boundingBox.height = radius;
        end
        cellProps(i).images(j).stage = nameparts.pcEvent;
        cellProps(i).images(j).type = [];
        j = j + 1;
        
    end
    tline = fgetl(fid);
end
fclose(fid);

%% analyze structure containing elphys data
dayIdx = 1;
matfile = load(elphysStructpath, 'propagated');
elphysStruct = matfile.propagated;
elphysDay = ['20', elphysStruct(dayIdx).fname(1:6)];
firstRecordDay = [num2str(cellProps(1).date.Year), num2str(cellProps(1).date.Month), num2str(cellProps(1).date.Day)];
while ~strcmp(elphysDay, firstRecordDay)
    dayIdx = dayIdx + 1;
    elphysDay = ['20', elphysStruct(dayIdx).fname(1:6)];
end
timeIdx = 0;
for k = 1:(length(cellProps) - 1)
    date = cellProps(k + 1).date;
    realtime = hms2realtime(date.Hour, date.Minute, date.Second);
    m = 1;
    while elphysStruct(dayIdx + timeIdx).IVtime < realtime
        cellProps(k).elphys(m).fpath = elphysStructpath;
        [h, mi, s] = realtime2hms(elphysStruct(dayIdx + timeIdx).IVtime);
        cellProps(k).elphys(m).time = [num2str(h) , ':', num2str(mi), ':', num2str(s)];
        cellProps(k).elphys(m).idx = dayIdx + timeIdx;
        timeIdx = timeIdx + 1;
        m = m + 1;
    end
end

%% upload to database
dbname = "mongoTest";
collname = "logTest";
conn = mongoTestOpening("localhost", 27017, dbname);
mongoTestInsertion(conn, collname, cellProps);
mongoTestClosing(conn);

%% output
result = cellProps;

end