source("prelude/prelude.R")

# TODO: This is for development purposes only. Remove this before merging.
test_df <- get_data_from_db("cog_8_85_heterogeneous.sqlite3")
test_df <- prepare_varience_data(test_df)