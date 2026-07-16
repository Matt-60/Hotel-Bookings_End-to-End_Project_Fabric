[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
shared #"raw bookings" = let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "ea2d8afd-031d-4660-b557-4daa26dc7cad"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "1c761ff9-684e-419c-8ad1-5216c5647b75"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "raw.bookings", ItemKind = "Table"]}[Data],
  #"Changed column type" = Table.TransformColumnTypes(#"Navigation 2", {{"booking_id", Int64.Type}, {"guest_id", Int64.Type}, {"room_id", Int64.Type}, {"check_in", type date}, {"check_out", type date}, {"status", type text}})
in
  #"Changed column type";
shared #"raw guests" = let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "ea2d8afd-031d-4660-b557-4daa26dc7cad"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "1c761ff9-684e-419c-8ad1-5216c5647b75"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "raw.guests", ItemKind = "Table"]}[Data],
  #"Changed column type" = Table.TransformColumnTypes(#"Navigation 2", {{"guest_id", Int64.Type}, {"name", type text}, {"email", type text}, {"country", type text}, {"phone", type text}})
in
  #"Changed column type";
shared #"raw hotels" = let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "ea2d8afd-031d-4660-b557-4daa26dc7cad"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "1c761ff9-684e-419c-8ad1-5216c5647b75"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "raw.hotels", ItemKind = "Table"]}[Data],
  #"Changed column type" = Table.TransformColumnTypes(#"Navigation 2", {{"name", type text}, {"city", type text}, {"country", type text}, {"rating", type number}, {"hotel_id", Int64.Type}})
in
  #"Changed column type";
shared #"raw reviews" = let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "ea2d8afd-031d-4660-b557-4daa26dc7cad"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "1c761ff9-684e-419c-8ad1-5216c5647b75"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "raw.reviews", ItemKind = "Table"]}[Data],
  #"Changed column type" = Table.TransformColumnTypes(#"Navigation 2", {{"review_id", Int64.Type}, {"booking_id", Int64.Type}, {"rating", Int64.Type}, {"comment", type text}}),
  #"Grouped rows" = Table.Group(#"Changed column type", {"booking_id"}, {{"Avg_rating", each List.Average([rating]), type nullable number}}),
  #"Rounded off" = Table.TransformColumns(#"Grouped rows", {{"Avg_rating", each Number.Round(_, 1), type number}})
in
  #"Rounded off";
shared #"raw rooms" = let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "ea2d8afd-031d-4660-b557-4daa26dc7cad"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "1c761ff9-684e-419c-8ad1-5216c5647b75"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "raw.rooms", ItemKind = "Table"]}[Data],
  #"Changed column type" = Table.TransformColumnTypes(#"Navigation 2", {{"room_id", Int64.Type}, {"hotel_id", Int64.Type}, {"price_per_night", Int64.Type}, {"room_type", type text}, {"is_available", type text}})
in
  #"Changed column type";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "Merge_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared Merge = let
  Source = Table.NestedJoin(#"raw bookings", {"guest_id"}, #"raw guests", {"guest_id"}, "raw guests", JoinKind.LeftOuter),
  #"Merged queries" = Table.NestedJoin(Source, {"room_id"}, #"raw rooms", {"room_id"}, "raw rooms", JoinKind.LeftOuter),
  #"Expanded raw guests" = Table.ExpandTableColumn(#"Merged queries", "raw guests", {"name", "email", "phone", "country"}, {"name", "email", "phone", "country"}),
  #"Expanded raw rooms" = Table.ExpandTableColumn(#"Expanded raw guests", "raw rooms", {"hotel_id", "room_type", "price_per_night", "is_available"}, {"hotel_id", "room_type", "price_per_night", "is_available"}),
  #"Merged queries 1" = Table.NestedJoin(#"Expanded raw rooms", {"hotel_id"}, #"raw hotels", {"hotel_id"}, "raw hotels", JoinKind.LeftOuter),
  #"Expanded raw hotels" = Table.ExpandTableColumn(#"Merged queries 1", "raw hotels", {"name", "city", "country", "rating"}, {"name.1", "city", "country.1", "rating"}),
  #"Merged queries 2" = Table.NestedJoin(#"Expanded raw hotels", {"booking_id"}, #"raw reviews", {"booking_id"}, "raw reviews", JoinKind.LeftOuter),
  #"Expanded raw reviews 1" = Table.ExpandTableColumn(#"Merged queries 2", "raw reviews", {"Avg_rating"}, {"Avg_rating"}),
  #"Sorted rows" = Table.Sort(#"Expanded raw reviews 1", {{"booking_id", Order.Ascending}}),
  #"Renamed columns" = Table.RenameColumns(#"Sorted rows", {{"status", "booking_status"}, {"name", "guest_name"}, {"is_available", "room_is_available"}, {"name.1", "hotel_name"}, {"city", "hotel_city"}, {"country.1", "hotel_country"}, {"rating", "hotel_rating"}, {"Avg_rating", "reviews_avg_rating"}, {"email", "guest_email"}, {"phone", "guest_phone"}, {"country", "guest_country"}}),
  #"Added custom" = Table.AddColumn(#"Renamed columns", "nights_stayed", each Duration.Days([check_out] - [check_in])),
  #"Added custom 1" = Table.AddColumn(#"Added custom", "total_price", each [nights_stayed] * [price_per_night]),
  #"Added custom 2" = Table.AddColumn(#"Added custom 1", "is_reviewed", each if [reviews_avg_rating] = null then false else true),
  #"Changed column type" = Table.TransformColumnTypes(#"Added custom 2", {{"nights_stayed", Int64.Type}, {"total_price", Int64.Type}, {"is_reviewed", type text}}),
  #"Reordered columns" = Table.ReorderColumns(#"Changed column type", {"booking_id", "guest_id", "room_id", "hotel_id", "price_per_night", "total_price", "hotel_rating", "reviews_avg_rating", "check_in", "check_out", "nights_stayed", "booking_status", "guest_name", "guest_email", "guest_phone", "guest_country", "room_type", "room_is_available", "hotel_name", "hotel_city", "hotel_country", "is_reviewed"}),
  #"Added custom 3" = Table.AddColumn(#"Reordered columns", "processed_date", each DateTime.LocalNow()),
  #"Changed column type 1" = Table.TransformColumnTypes(#"Added custom 3", {{"processed_date", type datetime}}),
  #"Renamed columns 1" = Table.RenameColumns(#"Changed column type 1", {{"processed_date", "silver_processed_date"}, {"reviews_avg_rating", "review_rating"}})
in
  #"Renamed columns 1";
shared Merge_DataDestination = let
  Pattern = Lakehouse.Contents([CreateNavigationProperties = false, EnableFolding = false, HierarchicalNavigation = true, EnableVorder = true, OutputMetadataRefresh = true]),
  Navigation_1 = Pattern{[workspaceId = "ea2d8afd-031d-4660-b557-4daa26dc7cad"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "1604b554-d8b5-41da-9253-b8626d725ff0"]}[Data],
  Navigation_3 = Navigation_2{[Id = "silver", ItemKind = "Schema"]}[Data],
  TableNavigation = Navigation_3{[Id = "Silver_OBT", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
