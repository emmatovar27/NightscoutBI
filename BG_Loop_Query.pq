let

    NS_table ="entries",
    Start = Date.ToText(Date.AddDays(Date.From(DateTime.LocalNow()),UserImportDays*-1),"yyyy-MM-dd"),
    Tokn =  if UserNS_Token is null then "" else "&token=" & UserNS_Token,
    
    NS_Source = Json.Document(Web.Contents(#"UserNS_URL",
    [RelativePath="/api/v1/" & NS_table & ".json?count=500000&find[dateString][$gte]="& Start & Tokn]
    )),
    
    #"Converted to Table" = Table.FromList(NS_Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"_id", "device", "dateString", "sgv", "direction", "trend"}, {"_id", "device", "dateString", "sgv", "direction", "trend"}),
    #"Changed Type8" = Table.TransformColumnTypes(#"Expanded Column1",{{"dateString", type datetimezone}}),
    #"Changed Type" = Table.TransformColumnTypes(#"Changed Type8",{{"dateString", type datetime}, {"sgv", Int64.Type}}),
    #"Filtered Rows" = Table.SelectRows(#"Changed Type", each [device] <> null and [device] <> ""),
    #"Sorted Rows1" = Table.Sort(#"Filtered Rows",{{"dateString", Order.Descending}}),
    #"Duplicated Column" = Table.DuplicateColumn(#"Sorted Rows1", "dateString", "dateString - Copy"),
    #"Changed Type1" = Table.TransformColumnTypes(#"Duplicated Column",{{"dateString - Copy", type date}}),
    #"Renamed Columns" = Table.RenameColumns(#"Changed Type1",{{"dateString - Copy", "EntriesDate"}}),
    #"Changed Type2" = Table.TransformColumnTypes(#"Renamed Columns",{{"dateString", type datetime}}),
    #"Duplicated Column1" = Table.DuplicateColumn(#"Changed Type2", "dateString", "dateString - Copy"),
    #"Changed Type3" = Table.TransformColumnTypes(#"Duplicated Column1",{{"dateString - Copy", type time}, {"dateString", type datetime}}),
    #"Renamed Columns1" = Table.RenameColumns(#"Changed Type3",{{"dateString - Copy", "EntriesTime"}}),
    #"Filtered Rows1" = Table.SelectRows(#"Renamed Columns1", each [sgv] <> null),
    #"Added Custom" = Table.AddColumn(#"Filtered Rows1", "Custom", each Table.AddColumn(#"Renamed Columns", "DateTime", each DateTime.From(Number.Round(288*Number.From(DateTime.From([dateString]))/1)/288))),
    Custom = #"Added Custom"{0}[Custom],
    #"Changed Type4" = Table.TransformColumnTypes(Custom,{{"dateString", type datetime}, {"DateTime", type datetime}}),
    #"Renamed Columns2" = Table.RenameColumns(#"Changed Type4",{{"DateTime", "DateTime5"}}),
    #"Removed Duplicates1" = Table.Distinct(#"Renamed Columns2", {"DateTime5"}),
    #"Added Custom1" = Table.AddColumn(#"Removed Duplicates1", "RefreshDateTime", each DateTime.LocalNow()),
    #"Changed Type5" = Table.TransformColumnTypes(#"Added Custom1",{{"RefreshDateTime", type datetime}}),
    #"Duplicated Column2" = Table.DuplicateColumn(#"Changed Type5", "DateTime5", "DateTime5 - Copy"),
    #"Changed Type6" = Table.TransformColumnTypes(#"Duplicated Column2",{{"DateTime5 - Copy", type time}}),
    #"Renamed Columns3" = Table.RenameColumns(#"Changed Type6",{{"DateTime5 - Copy", "Time5"}}),
    #"Removed Duplicates" = Table.Distinct(#"Renamed Columns3", {"DateTime5"}),
    #"Sorted Rows" = Table.Sort(#"Removed Duplicates",{{"dateString", Order.Descending}}),
    #"Added Index" = Table.AddIndexColumn(#"Sorted Rows", "Index", 0, 1),
    #"Added Index1" = Table.AddIndexColumn(#"Added Index", "Index.1", 1, 1),
    #"Merged Queries" = Table.NestedJoin(#"Added Index1", {"Index"}, #"Added Index1", {"Index.1"}, "Renamed Columns4", JoinKind.LeftOuter),
    #"Expanded Renamed Columns4" = Table.ExpandTableColumn(#"Merged Queries", "Renamed Columns4", {"dateString", "sgv"}, {"Renamed Columns4.dateString", "Renamed Columns4.sgv"}),
    #"Renamed Columns5" = Table.RenameColumns(#"Expanded Renamed Columns4",{{"Renamed Columns4.sgv", "PrevSGV"}, {"Renamed Columns4.dateString", "PrevDateString"}}),
    #"Reordered Columns" = Table.ReorderColumns(#"Renamed Columns5",{"_id", "device", "sgv", "PrevSGV", "dateString", "PrevDateString", "direction", "trend", "EntriesDate", "DateTime5", "RefreshDateTime", "Time5", "Index", "Index.1"}),
    #"Added Custom2" = Table.AddColumn(#"Reordered Columns", "SGV_PrevAbsChg", each Number.Abs([PrevSGV]-[sgv])),
    #"Reordered Columns1" = Table.ReorderColumns(#"Added Custom2",{"device", "sgv", "PrevSGV", "SGV_PrevAbsChg", "dateString", "direction", "trend", "EntriesDate", "DateTime5", "RefreshDateTime", "Time5", "Index", "Index.1"}),
    #"Changed Type7" = Table.TransformColumnTypes(#"Reordered Columns1",{{"SGV_PrevAbsChg", Int64.Type}}),
    #"Renamed Columns4" = Table.RenameColumns(#"Changed Type7",{{"device", "CGM device"}})

in
      #"Renamed Columns4"