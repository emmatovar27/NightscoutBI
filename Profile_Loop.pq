let

    NS_table ="profile",
    Start = Date.ToText(Date.AddDays(Date.From(DateTime.LocalNow()),UserImportDays*-1),"yyyy-MM-dd"),
    Tokn =  if UserNS_Token is null then "" else "&token=" & UserNS_Token,
    
    NS_Source = Json.Document(Web.Contents(#"UserNS_URL",
    [RelativePath="/api/v1/" & NS_table & ".json?count=500000&find[dateString][$gte]="& Start & Tokn]
    )),
    #"Converted to Table" = Table.FromList(NS_Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"startDate", "units", "enteredBy", "store"}, {"startDate", "units", "enteredBy", "store"}),
    #"Filtered Rows" = Table.SelectRows(#"Expanded Column1", let latest = List.Max(#"Expanded Column1"[startDate]) in each [startDate] = latest),
    #"Changed Type" = Table.TransformColumnTypes(#"Filtered Rows",{{"startDate", type datetime}}),
    #"Expanded store" = Table.ExpandRecordColumn(#"Changed Type", "store", {"Default"}, {"Default"}),
    #"Expanded Default" = Table.ExpandRecordColumn(#"Expanded store", "Default", {"sens", "basal", "carbratio", "target_low", "delay", "carbs_hr", "timezone", "target_high", "dia"}, {"Default.sens", "Default.basal", "Default.carbratio", "Default.target_low", "Default.delay", "Default.carbs_hr", "Default.timezone", "Default.target_high", "Default.dia"}),
    #"Added Custom" = Table.AddColumn(#"Expanded Default", "Custom", each Table.FromColumns({[Default.sens],[Default.basal],[Default.carbratio],[Default.target_low],[Default.target_high]})),
    #"Expanded Custom" = Table.ExpandTableColumn(#"Added Custom", "Custom", {"Column1", "Column2", "Column3", "Column4", "Column5"}, {"sens", "basals", "carbratio", "target_low", "target_high"}),
    #"Expanded sens" = Table.ExpandRecordColumn(#"Expanded Custom", "sens", {"timeAsSeconds", "time", "value"}, {"sens.timeAsSeconds", "sens.time", "sens.value"}),
    #"Expanded basals" = Table.ExpandRecordColumn(#"Expanded sens", "basals", {"time", "value", "timeAsSeconds"}, {"basals.time", "basals.value", "basals.timeAsSeconds"}),
    #"Expanded carbratio" = Table.ExpandRecordColumn(#"Expanded basals", "carbratio", {"value", "timeAsSeconds", "time"}, {"carbratio.value", "carbratio.timeAsSeconds", "carbratio.time"}),
    #"Expanded target_low" = Table.ExpandRecordColumn(#"Expanded carbratio", "target_low", {"time", "timeAsSeconds", "value"}, {"target_low.time", "target_low.timeAsSeconds", "target_low.value"}),
    #"Expanded target_high" = Table.ExpandRecordColumn(#"Expanded target_low", "target_high", {"value", "time", "timeAsSeconds"}, {"target_high.value", "target_high.time", "target_high.timeAsSeconds"}),
    #"Removed Columns" = Table.RemoveColumns(#"Expanded target_high",{"Default.sens", "Default.basal", "Default.carbratio", "Default.target_low", "Default.target_high"})
in
    #"Removed Columns"
